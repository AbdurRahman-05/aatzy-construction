import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants.dart';
import '../auth_provider.dart';

class VerificationPendingScreen extends ConsumerStatefulWidget {
  final String email;
  final String password;

  const VerificationPendingScreen({super.key, required this.email, required this.password});

  @override
  ConsumerState<VerificationPendingScreen> createState() => _VerificationPendingScreenState();
}

class _VerificationPendingScreenState extends ConsumerState<VerificationPendingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.email.isNotEmpty && widget.password.isNotEmpty) {
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        _checkApproval();
      });
    }
  }

  Future<void> _checkApproval() async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/providers/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'password': widget.password,
        }),
      );

      if (response.statusCode == 200) {
        _timer?.cancel();
        final data = jsonDecode(response.body);
        if (mounted) {
          ref.read(authProvider.notifier).login(data['provider'], 'PROVIDER');
          context.go('/provider-home');
        }
      }
    } catch (e) {
      // Ignore network errors during polling
    }
  }

  Future<void> _makeCall() async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: '+919986232326',
    );
    try {
      final canLaunch = await canLaunchUrl(launchUri);
      if (!mounted) return;
      if (canLaunch) {
        await launchUrl(launchUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer. Call support at +91 9986232326.')),
        );
      }
    } catch (e) {
      debugPrint('Error calling: $e');
    }
  }

  Future<void> _sendText() async {
    final String textMsg = 'Hi BuildConnect Support, I registered as a provider and am waiting for profile approval.';
    final Uri whatsappUri = Uri.parse('https://wa.me/919986232326?text=${Uri.encodeComponent(textMsg)}');
    try {
      final canLaunchWhatsapp = await canLaunchUrl(whatsappUri);
      if (!mounted) return;
      if (canLaunchWhatsapp) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        final Uri smsUri = Uri(
          scheme: 'sms',
          path: '+919986232326',
          queryParameters: <String, String>{
            'body': textMsg,
          },
        );
        final canLaunchSms = await canLaunchUrl(smsUri);
        if (!mounted) return;
        if (canLaunchSms) {
          await launchUrl(smsUri);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch SMS. Support number: +91 9986232326.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error texting: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF0F9B8E) : const Color(0xFF064354);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121B22) : Colors.white,
      appBar: AppBar(
        title: const Text('Verification Pending', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : const Color(0xFF064354),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () async {
              _timer?.cancel();
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Icon block
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    size: 80,
                    color: Colors.amber,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Text Content
              Text(
                'Your profile is under review',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF064354),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Our admin team is currently verifying your business documents. This typically takes 24 to 48 hours to activate your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.5,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 48),

              // Customer Support Card Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.support_agent_rounded, color: Colors.amber, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Need Urgent Activation?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : const Color(0xFF064354),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Contact our support desk to fast-track your approval process.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _makeCall,
                            icon: const Icon(Icons.phone_rounded, size: 18),
                            label: const Text('Call Support'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _sendText,
                            icon: const Icon(Icons.message_rounded, size: 18),
                            label: const Text('Text Support'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryColor,
                              side: BorderSide(color: primaryColor, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Bottom status text (quiet notice without spinner)
              Text(
                'You will be automatically logged in once verified.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
