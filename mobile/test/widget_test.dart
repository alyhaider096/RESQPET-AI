import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:resqpet_ai/api_client.dart';
import 'package:resqpet_ai/main.dart';

void main() {
  testWidgets(
      'coordinator verification refreshes without returning a Future from setState',
      (tester) async {
    final api = VerifyTestApi();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: CasesPanel(
      api: api,
      session: const Session(
          token: 'test',
          userId: 'coordinator',
          email: 'test@example.test',
          fullName: 'Coordinator',
          role: 'ngo_coordinator',
          organizationId: 'org'),
    ))));
    await tester.pump();
    await tester.tap(find.text('Verify'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(api.verified, isTrue);
    expect(find.text('Assign'), findsOneWidget);
  });
  testWidgets('shows branded splash then login screen', (tester) async {
    await tester.pumpWidget(const ResQPetApp());
    expect(find.text('ResQPet AI'), findsOneWidget);
    expect(find.text('Rescue • Care • Rehome'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Welcome to ResQPet'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}

class VerifyTestApi extends ApiClient {
  bool verified = false;
  @override
  Future<List<Map<String, dynamic>>> getCases() async => [
        {
          'id': 'case',
          'case_reference': 'RQP-TEST',
          'species': 'cat',
          'district': 'Islamabad',
          'priority': 'urgent',
          'status': verified ? 'verified' : 'reported',
          'visible_condition': 'Injured cat',
          'version': verified ? 2 : 1,
        }
      ];

  @override
  Future<Map<String, dynamic>> verifyCase(String caseId) async {
    verified = true;
    return (await getCases()).first;
  }
}
