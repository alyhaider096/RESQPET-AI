import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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
  String _baseUrl = apiBaseUrl;
  String get backendUrl => _baseUrl;

  Future<void> restoreBackendUrl() async {
    _baseUrl = await _storage.read(key: 'backend_url') ?? apiBaseUrl;
  }

  Future<void> setBackendUrl(String value) async {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        !(uri.scheme == 'https' ||
            (uri.scheme == 'http' &&
                {'127.0.0.1', 'localhost', '10.0.2.2'}.contains(uri.host)))) {
      throw ApiException(
          'Enter an HTTPS backend origin, such as https://your-demo.trycloudflare.com',
          422);
    }
    _baseUrl = uri.origin;
    _token = null;
    await _storage.delete(key: 'access_token');
    await _storage.write(key: 'backend_url', value: _baseUrl);
  }

  static const requestTimeout = Duration(seconds: 20);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<http.Response> _withTimeout(Future<http.Response> request) async {
    try {
      return await request.timeout(requestTimeout);
    } on TimeoutException {
      throw ApiException(
        'The rescue server took too long to respond. Please try again.',
        408,
      );
    } on http.ClientException {
      throw ApiException(
          'Cannot reach the rescue server. Check your connection and the demo server address.',
          503);
    }
  }

  Future<dynamic> _decode(http.Response response) async {
    dynamic body;
    try {
      body = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      throw ApiException(
          'The demo server is unavailable. Check the server connection and try again.',
          response.statusCode >= 400 ? response.statusCode : 502);
    }
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
    final response = await _withTimeout(
      _http.post(
        Uri.parse('$_baseUrl/api/v1/auth/login'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'password': password}),
      ),
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
    final response = await _withTimeout(
      _http.get(
        Uri.parse('$_baseUrl/api/v1/auth/me'),
        headers: _headers,
      ),
    );
    return await _decode(response) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getCases() async {
    final response = await _withTimeout(
      _http.get(
        Uri.parse('$_baseUrl/api/v1/cases'),
        headers: _headers,
      ),
    );
    return (await _decode(response) as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createCase(Map<String, dynamic> data) async {
    final response = await _withTimeout(
      _http.post(
        Uri.parse('$_baseUrl/api/v1/cases'),
        headers: _headers,
        body: jsonEncode(data),
      ),
    );
    return await _decode(response) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getMapCases() async {
    final response = await _withTimeout(_http.get(
      Uri.parse('$_baseUrl/api/v1/map/cases'),
      headers: _headers,
    ));
    return (await _decode(response) as List).cast<Map<String, dynamic>>();
  }

  Future<void> uploadPhoto(String caseId, Uint8List bytes) async {
    final request = http.MultipartRequest(
        'POST', Uri.parse('$_baseUrl/api/v1/cases/$caseId/photo'));
    request.headers['Authorization'] = 'Bearer $_token';
    request.files.add(http.MultipartFile.fromBytes('file', bytes,
        filename: 'rescue-photo.jpg'));
    final response =
        await _withTimeout(_http.send(request).then(http.Response.fromStream));
    await _decode(response);
  }

  Future<Uint8List> getPhoto(String caseId) async {
    final response = await _withTimeout(_http.get(
      Uri.parse('$_baseUrl/api/v1/cases/$caseId/photo'),
      headers: _headers,
    ));
    if (response.statusCode != 200) {
      throw ApiException('Photo could not be loaded', response.statusCode);
    }
    return response.bodyBytes;
  }

  Future<Map<String, dynamic>> verifyCase(String caseId) async {
    final response = await _withTimeout(
      _http.post(
        Uri.parse('$_baseUrl/api/v1/cases/$caseId/verify'),
        headers: _headers,
        body: '{}',
      ),
    );
    return await _decode(response) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getVolunteers() async {
    final response = await _withTimeout(
      _http.get(
        Uri.parse('$_baseUrl/api/v1/users/volunteers'),
        headers: _headers,
      ),
    );
    return (await _decode(response) as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> assignCase(
      String caseId, String volunteerId) async {
    final response = await _withTimeout(
      _http.post(
        Uri.parse('$_baseUrl/api/v1/cases/$caseId/assign'),
        headers: _headers,
        body: jsonEncode({'volunteer_id': volunteerId}),
      ),
    );
    return await _decode(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateStatus(
    String caseId,
    String status,
    int expectedVersion,
  ) async {
    final response = await _withTimeout(
      _http.patch(
        Uri.parse('$_baseUrl/api/v1/cases/$caseId/status'),
        headers: _headers,
        body: jsonEncode({
          'status': status,
          'expected_version': expectedVersion,
        }),
      ),
    );
    return await _decode(response) as Map<String, dynamic>;
  }

  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: 'access_token');
  }

  Future<String> askAssistant(List<Map<String, String>> messages) async {
    final response = await _withTimeout(_http.post(
      Uri.parse('$_baseUrl/api/v1/assistant/chat'),
      headers: _headers,
      body: jsonEncode({'messages': messages}),
    ));
    return (await _decode(response) as Map<String, dynamic>)['reply'] as String;
  }

  Future<List<Map<String, dynamic>>> getCare(String resource) async {
    final response = await _withTimeout(_http
        .get(Uri.parse('$_baseUrl/api/v1/care/$resource'), headers: _headers));
    return (await _decode(response) as List).cast<Map<String, dynamic>>();
  }

  Future<void> requestConsultation(Map<String, dynamic> data) async {
    await _decode(await _withTimeout(_http.post(
        Uri.parse('$_baseUrl/api/v1/care/consultations'),
        headers: _headers,
        body: jsonEncode(data))));
  }

  Future<void> updateConsultation(String id, Map<String, dynamic> data) async {
    await _decode(await _withTimeout(_http.patch(
        Uri.parse('$_baseUrl/api/v1/care/consultations/$id'),
        headers: _headers,
        body: jsonEncode(data))));
  }
}
