import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'constants.dart';

void showApiSettingsDialog(BuildContext context, {VoidCallback? onSave}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => const ApiSettingsDialog(),
  ).then((_) {
    if (onSave != null) onSave();
  });
}

class ApiSettingsDialog extends StatefulWidget {
  const ApiSettingsDialog({super.key});

  @override
  State<ApiSettingsDialog> createState() => _ApiSettingsDialogState();
}

class _ApiSettingsDialogState extends State<ApiSettingsDialog> {
  final TextEditingController _urlController = TextEditingController();
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = apiBaseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = 'Testing connection...';
      _testSuccess = false;
    });

    final testUrl = _urlController.text.trim();
    if (testUrl.isEmpty) {
      setState(() {
        _isTesting = false;
        _testResult = 'URL cannot be empty';
      });
      return;
    }

    try {
      // Test endpoint using a quick GET request with 3 second timeout
      final uri = Uri.parse(testUrl.endsWith('/api') ? '$testUrl/social/feed' : '$testUrl/api/social/feed');
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = response.statusCode == 200 || response.statusCode == 404; // 404 is acceptable (server responded)
          _testResult = _testSuccess ? 'Connected successfully! ✅' : 'Server responded with code ${response.statusCode} ⚠️';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testResult = 'Connection failed: ${e.toString().split('\n').first} ❌';
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    final newUrl = _urlController.text.trim();
    if (newUrl.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url_override', newUrl);
    apiBaseUrl = newUrl;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API URL updated to: $newUrl'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_base_url_override');

    String defaultUrl = "http://127.0.0.1:3000/api";
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.isPhysicalDevice) {
        defaultUrl = "http://127.0.0.1:3000/api";
      } else {
        defaultUrl = "http://10.0.2.2:3000/api";
      }
    }

    setState(() {
      _urlController.text = defaultUrl;
      _testResult = 'Reset to default. Please test/save.';
      _testSuccess = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.settings_ethernet, color: Colors.blue, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Network Settings',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Configure the server API address to match your testing environment:',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'API Base URL',
                  hintText: 'e.g., http://192.168.1.10:3000/api',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.link),
                ),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Emulator (10.0.2.2)'),
                    onPressed: () => setState(() => _urlController.text = 'http://10.0.2.2:3000/api'),
                  ),
                  ActionChip(
                    label: const Text('USB Loopback (127.0.0.1)'),
                    onPressed: () => setState(() => _urlController.text = 'http://127.0.0.1:3000/api'),
                  ),
                  ActionChip(
                    label: const Text('Wi-Fi PC (192.168.1.10)'),
                    onPressed: () => setState(() => _urlController.text = 'http://192.168.1.10:3000/api'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_testResult != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _testSuccess ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _testSuccess ? Colors.green.shade200 : Colors.red.shade200),
                  ),
                  child: Text(
                    _testResult!,
                    style: TextStyle(
                      color: _testSuccess ? Colors.green.shade800 : Colors.red.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _resetToDefault,
                    child: const Text('Reset', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _isTesting ? null : _testConnection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isTesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Test'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
