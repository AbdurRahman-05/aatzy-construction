import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailAlerts = false;
  bool _locationServices = true;
  bool _darkMode = false;

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New passwords do not match!'), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green),
              );
            },
            child: const Text('UPDATE'),
          ),
        ],
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
                style: const TextStyle(height: 1.6, fontSize: 14, color: Colors.black87),
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
                  onChanged: (val) => setState(() => _pushNotifications = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.email, color: Colors.orange),
                  title: const Text('Email Alerts'),
                  subtitle: const Text('Receive digests and billing invoices'),
                  value: _emailAlerts,
                  onChanged: (val) => setState(() => _emailAlerts = val),
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
                  onChanged: (val) => setState(() => _locationServices = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode, color: Colors.purple),
                  title: const Text('Dark Theme'),
                  subtitle: const Text('Toggle between dark and light themes'),
                  value: _darkMode,
                  onChanged: (val) => setState(() => _darkMode = val),
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
