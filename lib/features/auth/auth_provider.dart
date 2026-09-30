import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/push_notification_service.dart';

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
  @override
  AuthState build() {
    _loadPersistedAuth();
    return AuthState(isInitialized: false);
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
      } else {
        state = AuthState(isInitialized: true);
      }
    } catch (e) {
      debugPrint('Error loading persisted auth: $e');
      state = AuthState(isInitialized: true);
    }
  }

  Future<void> login(Map<String, dynamic> data, String role) async {
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
    }
  }

  Future<void> updateProfileImage(String? image) async {
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
