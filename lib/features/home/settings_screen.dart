import 'package:flutter/material.dart';
import 'package:construction_app/core/widgets/bento.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:construction_app/core/api_http.dart' as http;
import 'dart:convert';
import '../auth/auth_provider.dart';
import '../../core/constants.dart';
import '../../core/services/push_notification_service.dart';
import '../../main.dart'; // import themeModeProvider
import 'widgets/user_tutorial_dialog.dart';
// import '../../core/services/subscription_service.dart';
// import '../subscription/widgets/provider_subscription_modal.dart';

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
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green),
                            );
                          }
                        } else {
                          final errorMsg = jsonDecode(response.body)['error'] ?? 'Failed to update password';
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
                            );
                          }
                        }
                      } catch (e) {
                        debugPrint('Change password error: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Network error, please try again.'), backgroundColor: Colors.red),
                          );
                        }
                      } finally {
                        if (context.mounted) {
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
    // final auth = ref.watch(authProvider);
    // final subState = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: BentoAppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
        children: [
          /*
          // Membership & Billing disabled and hidden from UI
          if (auth.role == 'PROVIDER') ...[
            _buildSectionHeader('Membership & Billing'),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD97706)),
                ),
                title: Text(
                  subState.isSubscribed ? 'Annual Pro Plan (Active)' : 'Annual Pro Plan (Inactive)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  subState.isSubscribed
                      ? '${subState.daysLeft} Days Remaining • ₹5,999/yr'
                      : 'Subscribe now to unlock consumer leads & chat',
                  style: TextStyle(
                    color: subState.isSubscribed ? const Color(0xFF0F766E) : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: () => showProviderSubscriptionModal(context),
                  child: Text(
                    subState.isSubscribed ? 'Manage' : 'Subscribe',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          */
          _buildAccountCard(),
          const SizedBox(height: 6),
          _buildSectionHeader('Notifications'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const BentoIconBubble(icon: Icons.notifications_active, color: Colors.blue, size: 38),
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Get real-time updates on quotes & tasks'),
                  value: _pushNotifications,
                  onChanged: (val) => _updatePreference('push_notifications', val),
                ),
                const Divider(height: 1, indent: 72, endIndent: 16),
                ListTile(
                  leading: const BentoIconBubble(icon: Icons.send_to_mobile_rounded, color: Color(0xFF0F766E), size: 38),
                  title: const Text('Send Test Notification', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Preview how leads and job alerts appear'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () async {
                    await PushNotificationService().showTestNotification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Test notification sent to your system tray!'),
                          backgroundColor: Color(0xFF0F766E),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1, indent: 72, endIndent: 16),
                SwitchListTile(
                  secondary: const BentoIconBubble(icon: Icons.email, color: Color(0xFFE11D48), size: 38),
                  title: const Text('Email Alerts'),
                  subtitle: const Text('Receive digests and billing invoices'),
                  value: _emailAlerts,
                  onChanged: (val) => _updatePreference('email_alerts', val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildSectionHeader('App Configuration'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const BentoIconBubble(icon: Icons.location_on, color: Colors.red, size: 38),
                  title: const Text('Location Services'),
                  subtitle: const Text('Allow finding nearby active providers'),
                  value: _locationServices,
                  onChanged: (val) => _updatePreference('location_services', val),
                ),
                const Divider(height: 1, indent: 72, endIndent: 16),
                SwitchListTile(
                  secondary: const BentoIconBubble(icon: Icons.dark_mode, color: Colors.purple, size: 38),
                  title: const Text('Dark Theme'),
                  subtitle: const Text('Toggle between dark and light themes'),
                  value: _darkMode,
                  onChanged: (val) => _updatePreference('dark_mode', val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildSectionHeader('Tutorial & App Guide'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const BentoIconBubble(icon: Icons.school, color: Color(0xFF8B5CF6), size: 38),
                  title: const Text('View User Side Benefits Tutorial'),
                  subtitle: const Text('Re-open the interactive pop-up guide'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    final auth = ref.read(authProvider);
                    UserTutorialDialog.show(context, userId: auth.id, force: true);
                  },
                ),
                const Divider(height: 1, indent: 72, endIndent: 16),
                ListTile(
                  leading: const BentoIconBubble(icon: Icons.restart_alt, color: Colors.blueGrey, size: 38),
                  title: const Text('Reset Tutorial Status'),
                  subtitle: const Text('Pop up tutorial automatically on next home view'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final auth = ref.read(authProvider);
                    await UserTutorialDialog.resetSeenState(userId: auth.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tutorial status reset! It will pop up next time you open Home.')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildSectionHeader('Security & Privacy'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const BentoIconBubble(icon: Icons.lock, color: Colors.green, size: 38),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showChangePasswordDialog,
                ),
                const Divider(height: 1, indent: 72, endIndent: 16),
                ListTile(
                  leading: const BentoIconBubble(icon: Icons.gavel, color: Colors.teal, size: 38),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDocumentModal(
                    'Terms of Service',
                    'Welcome to Connectzy!\n\n1. Acceptance of Terms\nBy using our platform, you agree to comply with our general user terms and agreements.\n\n2. Service Provider Responsibility\nAll providers registered on our platform verify that their credentials, details, and works uploaded to portfolio are true and accurate.\n\n3. Consumer Guarantee\nConnectzy acts as an aggregation platform to connect building owners with contractors, engineers, and suppliers. Real-time contracts are signed directly between both parties.',
                  ),
                ),
                const Divider(height: 1, indent: 72, endIndent: 16),
                ListTile(
                  leading: const BentoIconBubble(icon: Icons.privacy_tip, color: Colors.indigo, size: 38),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDocumentModal(
                    'Privacy Policy',
                    'Privacy Policy for Connectzy App:\n\nWe care deeply about your privacy. We collect data regarding your coordinates (when location is enabled), profile bio, document copies for registration, and text messages sent during quote estimations to ensure safe transactions inside our application.\n\nWe never sell your identity details to third-party marketing companies.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Connectzy v1.0.0',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
          color: Bento.muted(isDark),
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildAccountCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = ref.watch(authProvider);
    final name = (auth.role == 'PROVIDER' ? (auth.businessName ?? auth.name) : auth.name) ?? 'Your account';
    return BentoCard(
      gradient: Bento.inkGradient,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          BentoAvatar(name: name, image: auth.profileImage, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -0.4),
                ),
                if ((auth.email ?? '').isNotEmpty)
                  Text(
                    auth.email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 12.5),
                  ),
              ],
            ),
          ),
          BentoPill(
            label: auth.role == 'PROVIDER' ? 'PARTNER' : 'CUSTOMER',
            color: Bento.accentLight,
            background: Colors.white.withValues(alpha: isDark ? 0.08 : 0.1),
          ),
        ],
      ),
    );
  }
}
