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
    await tester.pumpAndSettle();
    expect(find.text('Review rescue report'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Confirm verification'), 400,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Confirm verification'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(api.verified, isTrue);
    expect(find.text('Assign'), findsOneWidget);
  });
  testWidgets('coordinator selects a volunteer before assignment',
      (tester) async {
    final api = VerifyTestApi()..verified = true;
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
                    organizationId: 'org')))));
    await tester.pump();
    await tester.tap(find.text('Assign'));
    await tester.pumpAndSettle();
    expect(find.text('Assign rescue team'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Choose a rescue volunteer'), 400,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volunteer Two').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Confirm assignment'), 100,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Confirm assignment'));
    await tester.pumpAndSettle();
    expect(api.assignedId, 'volunteer-two');
    expect(tester.takeException(), isNull);
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
  String? assignedId;
  @override
  Future<List<Map<String, dynamic>>> getVolunteers() async => [
        {'id': 'volunteer-one', 'full_name': 'Volunteer One'},
        {'id': 'volunteer-two', 'full_name': 'Volunteer Two'},
      ];
  @override
  Future<Map<String, dynamic>> assignCase(
      String caseId, String volunteerId) async {
    assignedId = volunteerId;
    return (await getCases()).first;
  }

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
