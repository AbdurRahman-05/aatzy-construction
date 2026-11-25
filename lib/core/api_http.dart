/// Drop-in replacement for `package:http` that automatically attaches the
/// logged-in user's session token to requests sent to the Connectzy API.
///
/// Usage (same API as package:http):
///   import '../core/api_http.dart' as http;
///   final res = await http.get(Uri.parse('$apiBaseUrl/projects/$id'));
///
/// Requests to other hosts (Google, Unsplash, ...) are sent without the token.
library;

import 'dart:convert';

import 'package:http/http.dart' as base;
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

export 'package:http/http.dart' hide get, post, put, patch, delete, head, read, readBytes;

/// Holds the session token issued by the backend at login.
class AuthToken {
  AuthToken._();

  static const String prefsKey = 'auth_token';

  static String? _token;
  static bool _loaded = false;

  /// Called when the backend rejects the session (expired / missing token).
  /// Registered by AuthNotifier to force a logout.
  static Future<void> Function()? onSessionRejected;

  static Future<String?> get() async {
    if (!_loaded) {
      try {
        final prefs = await SharedPreferences.getInstance();
        _token = prefs.getString(prefsKey);
      } catch (_) {}
      _loaded = true;
    }
    return _token;
  }

  static Future<void> set(String? token) async {
    _token = (token != null && token.isNotEmpty) ? token : null;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) {
        await prefs.setString(prefsKey, _token!);
      } else {
        await prefs.remove(prefsKey);
      }
    } catch (_) {}
  }
}

bool _isApiRequest(Uri url) {
  try {
    final api = Uri.parse(apiBaseUrl);
    return url.host == api.host && url.port == api.port;
  } catch (_) {
    return false;
  }
}

Future<Map<String, String>?> _withAuth(Uri url, Map<String, String>? headers) async {
  if (!_isApiRequest(url)) return headers;
  final token = await AuthToken.get();
  if (token == null) return headers;
  return {...?headers, 'Authorization': 'Bearer $token'};
}

/// If the API says the session is missing/invalid, let the app log the user out.
void _checkSession(Uri url, base.Response response) {
  if (response.statusCode != 401 || !_isApiRequest(url)) return;
  try {
    final body = jsonDecode(response.body);
    final code = body is Map ? body['code']?.toString() : null;
    if (code == 'AUTH_INVALID' || code == 'AUTH_REQUIRED') {
      AuthToken.onSessionRejected?.call();
    }
  } catch (_) {}
}

Future<base.Response> get(Uri url, {Map<String, String>? headers}) async {
  final res = await base.get(url, headers: await _withAuth(url, headers));
  _checkSession(url, res);
  return res;
}

Future<base.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  final res = await base.post(url, headers: await _withAuth(url, headers), body: body, encoding: encoding);
  _checkSession(url, res);
  return res;
}

Future<base.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  final res = await base.put(url, headers: await _withAuth(url, headers), body: body, encoding: encoding);
  _checkSession(url, res);
  return res;
}

Future<base.Response> patch(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  final res = await base.patch(url, headers: await _withAuth(url, headers), body: body, encoding: encoding);
  _checkSession(url, res);
  return res;
}

Future<base.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  final res = await base.delete(url, headers: await _withAuth(url, headers), body: body, encoding: encoding);
  _checkSession(url, res);
  return res;
}
