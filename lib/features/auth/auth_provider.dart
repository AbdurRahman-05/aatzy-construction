import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final String? id;
  final String? name;
  final String? email;
  final String? businessName;
  final String? role; // 'CONSUMER' or 'PROVIDER'

  AuthState({this.id, this.name, this.email, this.businessName, this.role});

  AuthState copyWith({String? id, String? name, String? email, String? businessName, String? role}) {
    return AuthState(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      businessName: businessName ?? this.businessName,
      role: role ?? this.role,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState();
  }

  void login(Map<String, dynamic> data, String role) {
    if (role == 'PROVIDER') {
      state = AuthState(
        id: data['id'],
        name: data['ownerName'],
        businessName: data['businessName'],
        email: data['email'],
        role: 'PROVIDER',
      );
    } else {
      state = AuthState(
        id: data['id'],
        name: data['name'],
        email: data['email'],
        role: 'CONSUMER',
      );
    }
  }

  void logout() {
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
