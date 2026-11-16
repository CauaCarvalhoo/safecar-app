import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:piloto/screens/splash_screen.dart';

void main() {
  testWidgets('SafeCar inicia na tela de splash', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen()),
    );

    expect(find.text('SafeCar'), findsOneWidget);
    expect(find.text('Segurança automotiva inteligente'), findsOneWidget);

    // Descarta a tela antes do prazo de navegação. O timer deve ser cancelado.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));

    expect(tester.takeException(), isNull);
  });

  testWidgets('Splash navega para introdução após dois segundos',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/intro1': (context) =>
              const Scaffold(body: Center(child: Text('Introdução SafeCar'))),
        },
      ),
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Introdução SafeCar'), findsOneWidget);
    expect(find.text('SafeCar'), findsNothing);
  });
}
