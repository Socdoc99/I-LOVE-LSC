import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_love_lsc/core/setup/setup_needed_app.dart';
import 'package:i_love_lsc/features/lessons/presentation/widgets/option_button.dart';

void main() {
  testWidgets('OptionButton muestra la etiqueta y responde al toque', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OptionButton(label: 'Hola', onPressed: () => taps++),
        ),
      ),
    );

    expect(find.text('Hola'), findsOneWidget);
    await tester.tap(find.text('Hola'));
    expect(taps, 1);
  });

  testWidgets('OptionButton comunica el resultado con ícono, no solo con color', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              OptionButton(label: 'Correcta', onPressed: null, state: OptionState.correct),
              OptionButton(label: 'Incorrecta', onPressed: null, state: OptionState.wrong),
            ],
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsOneWidget);
  });

  testWidgets('sin Firebase configurado se explica qué falta', (tester) async {
    await tester.pumpWidget(const SetupNeededApp(error: 'prueba'));

    expect(find.text('Falta conectar Firebase'), findsOneWidget);
    expect(find.textContaining('flutterfire configure'), findsWidgets);
  });
}
