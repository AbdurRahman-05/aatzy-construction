import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  final String? id;
  final String? name;
  final String? email;
  final String? businessName;
  final String? role; // 'CONSUMER' or 'PROVIDER'
  final String? gstNumber;
  final bool isInitialized;

  AuthState({
    this.id,
    this.name,
    this.email,
    this.businessName,
    this.role,
    this.gstNumber,
    this.isInitialized = false,
  });

  AuthState copyWith({
    String? id,
    String? name,
    String? email,
    String? businessName,
    String? role,
    String? gstNumber,
    bool? isInitialized,
  }) {
    return AuthState(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      businessName: businessName ?? this.businessName,
      role: role ?? this.role,
      gstNumber: gstNumber ?? this.gstNumber,
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

      if (id != null && role != null) {
        state = AuthState(
          id: id,
          name: name,
          email: email,
          businessName: businessName,
          role: role,
          gstNumber: gstNumber,
          isInitialized: true,
        );
      } else {
        state = AuthState(isInitialized: true);
      }
    } catch (e) {
      debugPrint('Error loading persisted auth: $e');
      state = AuthState(isInitialized: true);
    }
  }

  Future<void> login(Map<String, dynamic> data, String role) async {
    final AuthState newState;
    if (role == 'PROVIDER') {
      newState = AuthState(
        id: data['id']?.toString(),
        name: data['ownerName']?.toString(),
        businessName: data['businessName']?.toString(),
        email: data['email']?.toString(),
        role: 'PROVIDER',
        gstNumber: data['gstNumber']?.toString(),
        isInitialized: true,
      );
    } else {
      newState = AuthState(
        id: data['id']?.toString(),
        name: data['name']?.toString(),
        email: data['email']?.toString(),
        role: 'CONSUMER',
        isInitialized: true,
      );
    }
    state = newState;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (newState.id != null) await prefs.setString('auth_id', newState.id!);
      if (newState.name != null) await prefs.setString('auth_name', newState.name!);
      if (newState.email != null) await prefs.setString('auth_email', newState.email!);
      if (newState.businessName != null) await prefs.setString('auth_businessName', newState.businessName!);
      if (newState.role != null) await prefs.setString('auth_role', newState.role!);
      if (newState.gstNumber != null) {
        await prefs.setString('auth_gstNumber', newState.gstNumber!);
      } else {
        await prefs.remove('auth_gstNumber');
      }
    } catch (e) {
      debugPrint('Error persisting auth: $e');
    }
  }

  Future<void> logout() async {
    state = AuthState(isInitialized: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_id');
      await prefs.remove('auth_name');
      await prefs.remove('auth_email');
      await prefs.remove('auth_businessName');
      await prefs.remove('auth_role');
      await prefs.remove('auth_gstNumber');
    } catch (e) {
      debugPrint('Error clearing persisted auth: $e');
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
