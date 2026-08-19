import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import 'auth_provider.dart';
import '../../core/api_settings_dialog.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/google_sign_in_helper.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? initialRole;
  const LoginScreen({super.key, this.initialRole});

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
    isProvider = widget.initialRole == 'provider';
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
            if (kIsWeb) {
              await GoogleSignIn.instance.initialize(clientId: fetchedId);
            } else {
              await GoogleSignIn.instance.initialize(serverClientId: fetchedId);
            }
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

      final url = isProvider 
          ? '$apiBaseUrl/providers/google-login' 
          : '$apiBaseUrl/users/google-login';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
        }),
      );

      final data = _parseResponse(response);

      if (response.statusCode == 200) {
        if (!mounted) return;
        if (isProvider) {
          if (data['exists'] == true) {
            ref.read(authProvider.notifier).login(data['provider'], 'PROVIDER');
            context.go('/provider-home');
          } else {
            // New provider sign-up via Google: navigate to stepper
            context.push('/provider-register', extra: {
              'isGoogleSignUp': true,
              'email': data['email'],
              'ownerName': data['name'],
            });
          }
        } else {
          ref.read(authProvider.notifier).login(data['user'], 'CONSUMER');
          context.go('/');
        }
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

  Future<void> _showOtpDialog({
    required String email,
    required String password,
    required String phone,
    required String verificationId,
    required bool isProviderLogin,
  }) async {
    final otpController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('2-Factor Authentication'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'An OTP has been sent to your registered phone number ending in ${phone.length > 4 ? phone.substring(phone.length - 4) : phone}.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 8),
                    decoration: InputDecoration(
                      hintText: '••••',
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isVerifying
                      ? null
                      : () async {
                          final code = otpController.text.trim();
                          if (code.length < 4) return;

                          final navigator = Navigator.of(context);
                          final goRouter = GoRouter.of(context);
                          final messenger = ScaffoldMessenger.of(context);

                          setDialogState(() => isVerifying = true);
                          try {
                            final response = await http.post(
                              Uri.parse(isProviderLogin
                                  ? '$apiBaseUrl/providers/login'
                                  : '$apiBaseUrl/users/login'),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({
                                'email': email,
                                'password': password,
                                'verificationId': verificationId,
                                'otpCode': code,
                              }),
                            );

                            final data = _parseResponse(response);

                            if (response.statusCode == 200) {
                              if (!mounted) return;
                              navigator.pop(); // Close dialog
                              if (isProviderLogin) {
                                ref.read(authProvider.notifier).login(data['provider'], 'PROVIDER');
                                goRouter.go('/provider-home');
                              } else {
                                ref.read(authProvider.notifier).login(data['user'], 'CONSUMER');
                                goRouter.go('/');
                              }
                            } else {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(content: Text(data['error'] ?? 'Incorrect OTP code')),
                              );
                              setDialogState(() => isVerifying = false);
                            }
                          } catch (e) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Verification failed due to connection error.')),
                            );
                            setDialogState(() => isVerifying = false);
                          }
                        },
                  child: isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    );
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

      final data = _parseResponse(response);

      if (response.statusCode == 200) {
        if (data['requiresOtp'] == true) {
          setState(() => _isLoading = false);
          _showOtpDialog(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            phone: data['phone'],
            verificationId: data['verificationId'],
            isProviderLogin: false,
          );
          return;
        }
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

  Future<void> _loginProvider() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/providers/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final data = _parseResponse(response);

      if (response.statusCode == 200) {
        if (data['requiresOtp'] == true) {
          setState(() => _isLoading = false);
          _showOtpDialog(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            phone: data['phone'],
            verificationId: data['verificationId'],
            isProviderLogin: true,
          );
          return;
        }
        if (!mounted) return;
        ref.read(authProvider.notifier).login(data['provider'], 'PROVIDER');
        context.go('/provider-home');
      } else if (response.statusCode == 403) {
        if (!mounted) return;
        context.go('/provider-verification-pending', extra: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        });
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
      backgroundColor: AppTheme.backgroundNeutral,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi_tethering, color: AppTheme.primaryOrange),
            tooltip: 'Network Settings',
            onPressed: () => showApiSettingsDialog(context),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Modern Header Badge
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.construction_rounded,
                    size: 40,
                    color: AppTheme.primaryOrange,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to manage your construction projects',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Main Login Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE8E8E5), width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Role Selector Pill
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F3),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => isProvider = false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !isProvider ? AppTheme.primaryOrange : Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Consumer',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: !isProvider ? Colors.white : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => isProvider = true),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isProvider ? AppTheme.primaryOrange : Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Provider',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: isProvider ? Colors.white : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(Icons.email_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            final email = _emailController.text.trim();
                            final role = isProvider ? 'provider' : 'consumer';
                            context.push(
                              Uri(
                                path: '/forgot-password',
                                queryParameters: {
                                  if (email.isNotEmpty) 'email': email,
                                  'role': role,
                                },
                              ).toString(),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: const Color(0xFF64748B),
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  if (isProvider) {
                                    _loginProvider();
                                  } else {
                                    _loginConsumer();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryOrange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Text(
                                  isProvider ? 'Sign In as Provider' : 'Sign In as Consumer',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () {
                          if (isProvider) {
                            context.push('/provider-register');
                          } else {
                            context.push('/register');
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryOrange,
                        ),
                        child: Text(
                          isProvider ? 'New Provider? Create Account' : 'New Consumer? Create Account',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'or continue with',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      buildGoogleSignInButton(
                        onPressed: _loginWithGoogle,
                        isLoading: _isLoading,
                        useCustomStyle: kIsWeb && _webClientId.isEmpty,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  dynamic _parseResponse(http.Response response) {
    if (response.body.isEmpty) {
      throw Exception("Server returned empty response (Status: ${response.statusCode}). Please make sure your Next.js backend server is running.");
    }
    try {
      return jsonDecode(response.body);
    } catch (e) {
      throw Exception("Invalid server response format (Status: ${response.statusCode}).");
    }
  }
}
