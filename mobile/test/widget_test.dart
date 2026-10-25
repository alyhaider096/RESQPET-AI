import 'package:flutter_test/flutter_test.dart';
import 'package:resqpet_ai/main.dart';

void main() {
  testWidgets('shows login screen', (tester) async {
    await tester.pumpWidget(const ResQPetApp());
    expect(find.text('ResQ Pet AI'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
