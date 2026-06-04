import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../auth/auth_provider.dart';
import '../../core/constants.dart';
import '../../main.dart'; // import themeModeProvider

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailAlerts = false;
  bool _locationServices = true;
  bool _darkMode = false;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _loadPreferences();
      _isInit = true;
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _emailAlerts = prefs.getBool('email_alerts') ?? false;
      _locationServices = prefs.getBool('location_services') ?? true;
      _darkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  Future<void> _updatePreference(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
    setState(() {
      if (key == 'push_notifications') _pushNotifications = val;
      if (key == 'email_alerts') _emailAlerts = val;
      if (key == 'location_services') _locationServices = val;
      if (key == 'dark_mode') {
        _darkMode = val;
        ref.read(themeModeProvider.notifier).toggleTheme(val);
      }
    });
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm New Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final oldPass = oldPasswordController.text.trim();
                      final newPass = newPasswordController.text.trim();
                      final confirmPass = confirmPasswordController.text.trim();

                      if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all fields.'), backgroundColor: Colors.red),
                        );
                        return;
                      }

                      if (newPass != confirmPass) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('New passwords do not match!'), backgroundColor: Colors.red),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      
                      final auth = ref.read(authProvider);
                      try {
                        final response = await http.post(
                          Uri.parse('$apiBaseUrl/auth/change-password'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'userId': auth.id,
                            'role': auth.role,
                            'oldPassword': oldPass,
                            'newPassword': newPass,
                          }),
                        );

                        if (response.statusCode == 200) {
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green),
                            );
                          }
                        } else {
                          final errorMsg = jsonDecode(response.body)['error'] ?? 'Failed to update password';
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
                            );
                          }
                        }
                      } catch (e) {
                        debugPrint('Change password error: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Network error, please try again.'), backgroundColor: Colors.red),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setDialogState(() => isSubmitting = false);
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('UPDATE'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDocumentModal(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                content,
                style: const TextStyle(height: 1.6, fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CLOSE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Notifications'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active, color: Colors.blue),
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Get real-time updates on quotes & tasks'),
                  value: _pushNotifications,
                  onChanged: (val) => _updatePreference('push_notifications', val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.email, color: Colors.orange),
                  title: const Text('Email Alerts'),
                  subtitle: const Text('Receive digests and billing invoices'),
                  value: _emailAlerts,
                  onChanged: (val) => _updatePreference('email_alerts', val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('App Configuration'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.location_on, color: Colors.red),
                  title: const Text('Location Services'),
                  subtitle: const Text('Allow finding nearby active providers'),
                  value: _locationServices,
                  onChanged: (val) => _updatePreference('location_services', val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode, color: Colors.purple),
                  title: const Text('Dark Theme'),
                  subtitle: const Text('Toggle between dark and light themes'),
                  value: _darkMode,
                  onChanged: (val) => _updatePreference('dark_mode', val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Security & Privacy'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock, color: Colors.green),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showChangePasswordDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.gavel, color: Colors.teal),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDocumentModal(
                    'Terms of Service',
                    'Welcome to Aatzy Construction!\n\n1. Acceptance of Terms\nBy using our platform, you agree to comply with our general user terms and agreements.\n\n2. Service Provider Responsibility\nAll providers registered on our platform verify that their credentials, details, and works uploaded to portfolio are true and accurate.\n\n3. Consumer Guarantee\nAatzy acts as an aggregation platform to connect building owners with contractors, engineers, and suppliers. Real-time contracts are signed directly between both parties.',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip, color: Colors.indigo),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDocumentModal(
                    'Privacy Policy',
                    'Privacy Policy for Aatzy Construction App:\n\nWe care deeply about your privacy. We collect data regarding your coordinates (when location is enabled), profile bio, document copies for registration, and text messages sent during quote estimations to ensure safe transactions inside our application.\n\nWe never sell your identity details to third-party marketing companies.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              'Aatzy v1.0.0',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54),
      ),
    );
  }
}
