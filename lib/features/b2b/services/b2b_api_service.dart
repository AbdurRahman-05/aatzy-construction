import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';

class B2BApiResponse {
  final int statusCode;
  final dynamic data;
  final bool success;

  B2BApiResponse({required this.statusCode, required this.data, required this.success});
}

class B2BApiService {
  Future<B2BApiResponse> get(String path, {Map<String, String>? queryParameters, Map<String, String>? headers}) async {
    try {
      Uri uri = Uri.parse('$apiBaseUrl$path');
      if (queryParameters != null && queryParameters.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParameters);
      }
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
      );
      final decoded = jsonDecode(response.body);
      return B2BApiResponse(
        statusCode: response.statusCode,
        data: decoded,
        success: response.statusCode >= 200 && response.statusCode < 300,
      );
    } catch (e) {
      return B2BApiResponse(statusCode: 500, data: {'error': e.toString()}, success: false);
    }
  }

  Future<B2BApiResponse> post(String path, {dynamic data, Map<String, String>? headers}) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: jsonEncode(data),
      );
      final decoded = jsonDecode(response.body);
      return B2BApiResponse(
        statusCode: response.statusCode,
        data: decoded,
        success: response.statusCode >= 200 && response.statusCode < 300,
      );
    } catch (e) {
      return B2BApiResponse(statusCode: 500, data: {'error': e.toString()}, success: false);
    }
  }

  Future<B2BApiResponse> put(String path, {dynamic data, Map<String, String>? headers}) async {
    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: jsonEncode(data),
      );
      final decoded = jsonDecode(response.body);
      return B2BApiResponse(
        statusCode: response.statusCode,
        data: decoded,
        success: response.statusCode >= 200 && response.statusCode < 300,
      );
    } catch (e) {
      return B2BApiResponse(statusCode: 500, data: {'error': e.toString()}, success: false);
    }
  }

  Future<B2BApiResponse> delete(String path, {Map<String, String>? headers}) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiBaseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
      );
      final decoded = jsonDecode(response.body);
      return B2BApiResponse(
        statusCode: response.statusCode,
        data: decoded,
        success: response.statusCode >= 200 && response.statusCode < 300,
      );
    } catch (e) {
      return B2BApiResponse(statusCode: 500, data: {'error': e.toString()}, success: false);
    }
  }
}
