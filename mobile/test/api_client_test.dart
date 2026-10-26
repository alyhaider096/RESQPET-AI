import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:resqpet_ai/api_client.dart';

void main() {
  test('expired tunnel HTML produces a readable sign-in error', () async {
    final api = ApiClient(
        httpClient: MockClient(
            (_) async => http.Response('<html>No tunnel</html>', 502)));
    await expectLater(
        api.login('demo@example.test', 'synthetic'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'status', 502)
            .having((e) => e.message, 'message', contains('demo server'))));
  });
  test('network failure produces a readable sign-in error', () async {
    final api = ApiClient(
        httpClient:
            MockClient((_) async => throw http.ClientException('offline')));
    await expectLater(api.login('demo@example.test', 'synthetic'),
        throwsA(isA<ApiException>()));
  });
}
