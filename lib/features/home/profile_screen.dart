import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../auth/auth_provider.dart';
import '../../core/constants.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _profileImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfileData();
    });
  }

  Future<void> _fetchProfileData() async {
    final auth = ref.read(authProvider);
    if (auth.id == null || auth.role != 'PROVIDER') return;

    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/providers/${auth.id}/profile'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['provider'];
        if (mounted) {
          setState(() {
            _profileImage = data['profileImage'];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching profile photo in profile tab: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final name = auth.businessName ?? auth.name ?? 'Guest User';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.shade100,
              backgroundImage: _profileImage != null && _profileImage!.isNotEmpty
                  ? MemoryImage(base64Decode(_profileImage!.split(',').last))
                  : null,
              child: _profileImage == null || _profileImage!.isEmpty
                  ? Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          if (auth.role == 'PROVIDER')
            ListTile(
              leading: const Icon(Icons.edit_note, color: Colors.blue), 
              title: const Text('Edit Profile'), 
              onTap: () async {
                await context.push('/provider-profile-edit');
                _fetchProfileData();
              },
            ),
          ListTile(
            leading: const Icon(Icons.settings), 
            title: const Text('Settings'), 
            onTap: () => context.push('/settings'),
          ),
          ListTile(
            leading: const Icon(Icons.help), 
            title: const Text('Help & Support'), 
            onTap: () => context.push('/help-support'),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red), 
            title: const Text('Logout', style: TextStyle(color: Colors.red)), 
            onTap: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
