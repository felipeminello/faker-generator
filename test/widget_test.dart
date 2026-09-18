// Widget tests for the generator app shell and the UUID page wiring.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid_generator/main.dart';

void main() {
  testWidgets('starts on the UUID page in the empty state', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('UUID v4'), findsWidgets);
    expect(find.text('Nenhum valor gerado ainda'), findsOneWidget);
  });

  testWidgets('generating a UUID replaces the empty state', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Gerar'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum valor gerado ainda'), findsNothing);
    expect(
      find.byType(SelectableText),
      findsOneWidget,
      reason: 'the generated value should be rendered',
    );
  });

  testWidgets('clearing returns to the empty state', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Gerar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum valor gerado ainda'), findsOneWidget);
  });

  testWidgets('navigates between generator features', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('CNPJ'));
    await tester.pumpAndSettle();

    expect(
      find.text('Cadastro Nacional da Pessoa Jurídica válido, com dígitos '
          'verificadores.'),
      findsOneWidget,
    );
  });
}
