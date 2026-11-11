import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/router.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/services/ad_popup_service.dart';

class AuthState {
  final String? id;
  final String? name;
  final String? email;
  final String? businessName;
  final String? role; // 'CONSUMER' or 'PROVIDER'
  final String? gstNumber;
  final String? profileImage;
  final bool isInitialized;

  AuthState({
    this.id,
    this.name,
    this.email,
    this.businessName,
    this.role,
    this.gstNumber,
    this.profileImage,
    this.isInitialized = false,
  });

  // Sentinel used so copyWith can distinguish "not passed" from "explicitly null"
  static const _sentinel = Object();

  AuthState copyWith({
    String? id,
    String? name,
    String? email,
    String? businessName,
    String? role,
    String? gstNumber,
    Object? profileImage = _sentinel,
    bool? isInitialized,
  }) {
    return AuthState(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      businessName: businessName ?? this.businessName,
      role: role ?? this.role,
      gstNumber: gstNumber ?? this.gstNumber,
      profileImage: identical(profileImage, _sentinel)
          ? this.profileImage
          : profileImage as String?,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  static AuthNotifier? _activeInstance;
  static bool _isForceLoggingOut = false;
  Timer? _accountCheckTimer;

  @override
  AuthState build() {
    _activeInstance = this;
    ref.onDispose(() {
      _accountCheckTimer?.cancel();
      _accountCheckTimer = null;
      if (_activeInstance == this) _activeInstance = null;
    });
    _loadPersistedAuth();
    return AuthState(isInitialized: false);
  }

  void _startAccountCheckTimer() {
    _accountCheckTimer?.cancel();
    _accountCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      validateAccountExists();
    });
  }

  /// Verifies with the server that the currently logged-in account still exists in the database.
  /// If the admin deleted the account from the admin panel, the server returns 404, which triggers immediate logout.
  Future<bool> validateAccountExists() async {
    final currentId = state.id;
    final currentRole = state.role;
    if (currentId == null || currentId.isEmpty || !state.isInitialized) {
      return true;
    }

    try {
      final endpoint = currentRole == 'PROVIDER'
          ? '$apiBaseUrl/providers/$currentId/profile'
          : '$apiBaseUrl/users/$currentId';

      final response = await http.get(Uri.parse(endpoint)).timeout(const Duration(seconds: 8));

      if (response.statusCode == 404) {
        debugPrint('[Auth] Account validation returned 404. Account was deleted on backend.');
        await forceLogout(reason: 'Your account has been deleted by an administrator.');
        return false;
      }
    } catch (e) {
      debugPrint('[Auth] Account validation check exception: $e');
    }
    return true;
  }

  /// Immediately terminates the session, wipes credentials, and navigates to the login screen with a dialog
  Future<void> forceLogout({String? reason}) async {
    if (_isForceLoggingOut) return;
    _isForceLoggingOut = true;

    try {
      _accountCheckTimer?.cancel();
      _accountCheckTimer = null;

      await logout();

      final context = rootNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        GoRouter.of(context).go('/login');

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.person_off_rounded, color: Colors.red, size: 28),
                SizedBox(width: 10),
                Text('Account Removed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Text(
              reason ?? 'Your account has been deleted by an administrator. You have been automatically logged out.',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('[Auth] Error during forceLogout: $e');
    } finally {
      Future.delayed(const Duration(seconds: 3), () {
        _isForceLoggingOut = false;
      });
    }
  }

  /// Static trigger so FCM notifications or background services can immediately force a logout
  static Future<void> triggerForceLogout({String? reason}) async {
    if (_activeInstance != null) {
      await _activeInstance!.forceLogout(reason: reason);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_id');
      await prefs.remove('auth_name');
      await prefs.remove('auth_email');
      await prefs.remove('auth_businessName');
      await prefs.remove('auth_role');
      await prefs.remove('auth_gstNumber');
      await prefs.remove('auth_profileImage');
      final context = rootNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        GoRouter.of(context).go('/login');
      }
    }
  }

  Future<void> _loadPersistedAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('auth_id');
      final name = prefs.getString('auth_name');
      final email = prefs.getString('auth_email');
      final businessName = prefs.getString('auth_businessName');
      final role = prefs.getString('auth_role');
      final gstNumber = prefs.getString('auth_gstNumber');
      final profileImage = prefs.getString('auth_profileImage');

      if (id != null && role != null) {
        state = AuthState(
          id: id,
          name: name,
          email: email,
          businessName: businessName,
          role: role,
          gstNumber: gstNumber,
          profileImage: profileImage,
          isInitialized: true,
        );
        PushNotificationService().syncFCMToken(userId: id, role: role);
        _startAccountCheckTimer();
      } else {
        state = AuthState(isInitialized: true);
      }
    } catch (e) {
      debugPrint('Error loading persisted auth: $e');
      state = AuthState(isInitialized: true);
    }
  }

  Future<void> login(Map<String, dynamic> data, String role) async {
    AdPopupService.resetSession();
    final prefs = await SharedPreferences.getInstance();
    final savedProfileImage = prefs.getString('auth_profileImage');

    final AuthState newState;
    if (role == 'PROVIDER') {
      newState = AuthState(
        id: data['id']?.toString(),
        name: data['ownerName']?.toString(),
        businessName: data['businessName']?.toString(),
        email: data['email']?.toString(),
        role: 'PROVIDER',
        gstNumber: data['gstNumber']?.toString(),
        profileImage: data['profileImage']?.toString() ?? savedProfileImage,
        isInitialized: true,
      );
    } else {
      newState = AuthState(
        id: data['id']?.toString(),
        name: data['name']?.toString(),
        email: data['email']?.toString(),
        role: 'CONSUMER',
        profileImage: data['profileImage']?.toString() ?? savedProfileImage,
        isInitialized: true,
      );
    }
    state = newState;

    try {
      if (newState.id != null) await prefs.setString('auth_id', newState.id!);
      if (newState.name != null) await prefs.setString('auth_name', newState.name!);
      if (newState.email != null) await prefs.setString('auth_email', newState.email!);
      if (newState.businessName != null) await prefs.setString('auth_businessName', newState.businessName!);
      if (newState.role != null) await prefs.setString('auth_role', newState.role!);
      if (newState.profileImage != null) await prefs.setString('auth_profileImage', newState.profileImage!);
      if (newState.gstNumber != null) {
        await prefs.setString('auth_gstNumber', newState.gstNumber!);
      } else {
        await prefs.remove('auth_gstNumber');
      }
    } catch (e) {
      debugPrint('Error persisting auth: $e');
    }

    if (newState.id != null && newState.role != null) {
      PushNotificationService().syncFCMToken(userId: newState.id, role: newState.role);
      _startAccountCheckTimer();
    }
  }

  Future<void> updateProfileImage(String? image) async {
    if (state.profileImage == image) return;
    state = state.copyWith(profileImage: image);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (image != null && image.isNotEmpty) {
        await prefs.setString('auth_profileImage', image);
      } else {
        await prefs.remove('auth_profileImage');
      }
    } catch (e) {
      debugPrint('Error persisting profile image: $e');
    }
  }

  Future<void> logout() async {
    _accountCheckTimer?.cancel();
    _accountCheckTimer = null;
    AdPopupService.resetSession();
    final oldId = state.id;
    final oldRole = state.role;

    state = AuthState(isInitialized: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_id');
      await prefs.remove('auth_name');
      await prefs.remove('auth_email');
      await prefs.remove('auth_businessName');
      await prefs.remove('auth_role');
      await prefs.remove('auth_gstNumber');
      await prefs.remove('auth_profileImage');
    } catch (e) {
      debugPrint('Error clearing persisted auth: $e');
    }

    // Explicitly unregister and clear device FCM token in database and local device
    try {
      await PushNotificationService().unregisterFCMToken(
        userId: oldId,
        role: oldRole,
      );
    } catch (e) {
      debugPrint('Error unregistering FCM token on logout: $e');
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
