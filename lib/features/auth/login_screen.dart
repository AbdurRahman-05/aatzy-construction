import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import 'auth_provider.dart';
import '../../core/api_settings_dialog.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/google_sign_in_helper.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool isProvider = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _webClientId = '';
  StreamSubscription? _googleAuthSubscription;

  @override
  void initState() {
    super.initState();
    _loadWebClientId();
    
    // Subscribe to Google Sign-In events on Web platform
    if (kIsWeb) {
      _googleAuthSubscription = GoogleSignIn.instance.authenticationEvents.listen((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _handleGoogleUser(event.user);
        }
      }, onError: (error) {
        debugPrint('Google Web Authentication stream error: $error');
      });
    }
  }

  Future<void> _loadWebClientId() async {
    final prefs = await SharedPreferences.getInstance();
    String savedId = prefs.getString('google_client_id_override') ?? '';
    
    if (mounted) {
      setState(() {
        _webClientId = savedId;
      });
    }

    // Attempt to fetch updated Client ID from backend in the background
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/users/google-client-id'))
          .timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fetchedId = data['clientId'] as String? ?? '';
        if (fetchedId.isNotEmpty && fetchedId != savedId) {
          await prefs.setString('google_client_id_override', fetchedId);
          
          try {
            await GoogleSignIn.instance.initialize(clientId: fetchedId);
          } catch (e) {
            debugPrint('Google Sign-In re-initialization warning: $e');
          }
          
          if (mounted) {
            setState(() {
              _webClientId = fetchedId;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Background fetch for Google Client ID failed: $e');
    }
  }

  Future<void> _handleGoogleUser(GoogleSignInAccount user) async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAuthentication auth = user.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null) {
        throw Exception("Failed to retrieve Google ID Token.");
      }

      final response = await http.post(
        Uri.parse('$apiBaseUrl/users/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;
        ref.read(authProvider.notifier).login(data['user'], 'CONSUMER');
        context.go('/');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Google login failed')),
        );
      }
    } catch (e) {
      debugPrint('Error handling Google User: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete Google Sign-In: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginConsumer() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;
        ref.read(authProvider.notifier).login(data['user'], 'CONSUMER');
        context.go('/');
      } else if (response.statusCode == 403) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval Pending: ${data['message']}')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Failed to reach server.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    if (kIsWeb && _webClientId.isEmpty) {
      // Show warning/error that Google Sign-in is not configured on the backend yet!
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Google Authentication Unavailable'),
          content: const Text(
            'Google Sign-In is not configured on the server.\n\n'
            'To enable it, please add the GOOGLE_CLIENT_ID environment variable in the backend (.env file) and restart the server.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Trigger the Google Authentication flow (on Web, GIS button handles this automatically; 
      // this authenticate() call will be executed on mobile platforms).
      final googleUser = await GoogleSignIn.instance.authenticate();
      await _handleGoogleUser(googleUser);
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _googleAuthSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi_tethering, color: Colors.white),
            tooltip: 'Network Settings',
            onPressed: () => showApiSettingsDialog(context),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.secondary,
              Theme.of(context).primaryColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Header with Logo
              SafeArea(
                child: Container(
                  height: 170,
                  alignment: Alignment.center,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(45),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom Form Card with Entry Animation
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 750),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 80 * (1.0 - value)),
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 230,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Text(
                          'hello!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Welcome to BuildConnect',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('Consumer'),
                            selected: !isProvider,
                            selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              color: !isProvider ? Theme.of(context).primaryColor : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) => setState(() => isProvider = false),
                          ),
                          const SizedBox(width: 16),
                          ChoiceChip(
                            label: const Text('Provider'),
                            selected: isProvider,
                            selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              color: isProvider ? Theme.of(context).primaryColor : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) => setState(() => isProvider = true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: Colors.grey.shade600),
                          floatingLabelStyle: TextStyle(color: Theme.of(context).primaryColor),
                          prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
                          ),
                        ),
                      ),
                      if (!isProvider) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(color: Colors.grey.shade600),
                            floatingLabelStyle: TextStyle(color: Theme.of(context).primaryColor),
                            prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () {
                            if (isProvider) {
                              context.push('/provider-login');
                            } else {
                              _loginConsumer();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                isProvider ? 'Provider Login' : 'Login',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          if (isProvider) {
                            context.push('/provider-register');
                          } else {
                            context.push('/register');
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                        child: Text(
                          isProvider ? 'Register as Service Provider' : 'New here? Register',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or continue with',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                      buildGoogleSignInButton(
                        onPressed: _loginWithGoogle,
                        isLoading: _isLoading,
                        useCustomStyle: kIsWeb && _webClientId.isEmpty,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
