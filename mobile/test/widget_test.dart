import 'package:flutter_test/flutter_test.dart';
import 'package:resqpet_ai/main.dart';

void main() {
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
