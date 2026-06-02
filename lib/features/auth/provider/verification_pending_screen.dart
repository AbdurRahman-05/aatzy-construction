import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verification Pending')),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.hourglass_empty, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            Text('Your profile is under review', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            const Text('Our admins are verifying your documents. This usually takes 24-48 hours.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            const Text('Automatically checking status...', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}
