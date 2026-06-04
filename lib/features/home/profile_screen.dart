import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final name = auth.businessName ?? auth.name ?? 'Guest User';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(radius: 50, child: Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 32))),
          const SizedBox(height: 16),
          Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          if (auth.role == 'PROVIDER')
            ListTile(
              leading: const Icon(Icons.edit_note, color: Colors.blue), 
              title: const Text('Edit Profile'), 
              onTap: () => context.push('/provider-profile-edit')
            ),
          ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), onTap: (){}),
          ListTile(leading: const Icon(Icons.help), title: const Text('Help & Support'), onTap: (){}),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red), 
            title: const Text('Logout', style: TextStyle(color: Colors.red)), 
            onTap: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            }
          ),
        ],
      ),
    );
  }
}
