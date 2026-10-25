import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

class ApiException implements Exception {
  ApiException(this.message, this.statusCode);
  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class Session {
  const Session({
    required this.token,
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
    required this.organizationId,
  });

  final String token;
  final String userId;
  final String email;
  final String fullName;
  final String role;
  final String? organizationId;
}

class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> _decode(http.Response response) async {
    final dynamic body =
        response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      Object? detail;
      if (body is Map<String, dynamic>) {
        detail = body['detail'];
        final error = body['error'];
        if (detail == null && error is Map<String, dynamic>) {
          detail = error['message'];
        }
      }
      throw ApiException(
          detail?.toString() ?? 'Request failed', response.statusCode);
    }
    return body;
  }

  Future<Session> login(String email, String password) async {
    final response = await _http.post(
      Uri.parse('$apiBaseUrl/api/v1/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );
    final body = await _decode(response) as Map<String, dynamic>;
    _token = body['access_token'] as String;
    await _storage.write(key: 'access_token', value: _token);
    final me = await getMe();
    return Session(
      token: _token!,
      userId: me['id'] as String,
      email: me['email'] as String,
      fullName: me['full_name'] as String,
      role: me['role'] as String,
      organizationId: me['organization_id'] as String?,
    );
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _http.get(
      Uri.parse('$apiBaseUrl/api/v1/auth/me'),
      headers: _headers,
    );
    return await _decode(response) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getCases() async {
    final response = await _http.get(
      Uri.parse('$apiBaseUrl/api/v1/cases'),
      headers: _headers,
    );
    return (await _decode(response) as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createCase(Map<String, dynamic> data) async {
    final response = await _http.post(
      Uri.parse('$apiBaseUrl/api/v1/cases'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return await _decode(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyCase(String caseId) async {
    final response = await _http.post(
      Uri.parse('$apiBaseUrl/api/v1/cases/$caseId/verify'),
      headers: _headers,
      body: '{}',
    );
    return await _decode(response) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getVolunteers() async {
    final response = await _http.get(
      Uri.parse('$apiBaseUrl/api/v1/users/volunteers'),
      headers: _headers,
    );
    return (await _decode(response) as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> assignCase(
      String caseId, String volunteerId) async {
    final response = await _http.post(
      Uri.parse('$apiBaseUrl/api/v1/cases/$caseId/assign'),
      headers: _headers,
      body: jsonEncode({'volunteer_id': volunteerId}),
    );
    return await _decode(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateStatus(
    String caseId,
    String status,
    int expectedVersion,
  ) async {
    final response = await _http.patch(
      Uri.parse('$apiBaseUrl/api/v1/cases/$caseId/status'),
      headers: _headers,
      body: jsonEncode({
        'status': status,
        'expected_version': expectedVersion,
      }),
    );
    return await _decode(response) as Map<String, dynamic>;
  }

  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: 'access_token');
  }
}
