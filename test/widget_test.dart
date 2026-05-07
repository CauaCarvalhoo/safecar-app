import 'package:flutter_test/flutter_test.dart';

import 'package:piloto/main.dart';

void main() {
  testWidgets('SafeCar inicia na tela de splash', (WidgetTester tester) async {
    await tester.pumpWidget(const SafeCarApp());
    expect(find.text('SafeCar'), findsOneWidget);
    expect(find.text('Segurança automotiva inteligente'), findsOneWidget);
  });
}
