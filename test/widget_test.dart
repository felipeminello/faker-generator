// Widget tests for the generator app shell and the UUID page wiring.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/main.dart';

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

  testWidgets('generates placeholder text on the Lorem Ipsum page', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Lorem'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum texto gerado ainda'), findsOneWidget);

    await tester.tap(find.text('Gerar'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum texto gerado ainda'), findsNothing);
    final generated = tester.widget<SelectableText>(
      find.byType(SelectableText),
    );
    expect(generated.data, startsWith('Lorem ipsum dolor sit amet'));
  });

  testWidgets('switching the Lorem unit resets the amount', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Lorem'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Palavras'));
    await tester.pumpAndSettle();

    expect(find.text('Quantidade de palavras'), findsOneWidget);
    expect(find.widgetWithText(TextField, '50'), findsOneWidget);
  });

  testWidgets('navigates between generator features', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('CNPJ'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Cadastro Nacional da Pessoa Jurídica válido, com dígitos '
        'verificadores.',
      ),
      findsOneWidget,
    );
  });

  group('phone-sized window', () {
    // Roughly an iPhone 15 in logical pixels.
    setUp(() => _setSurface(const Size(393, 852)));

    testWidgets('uses a bottom bar instead of the side rail', (tester) async {
      await tester.pumpWidget(const MyApp());

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('navigates from the bottom bar', (tester) async {
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.text('CPF'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Cadastro de Pessoa Física válido, com dígitos '
          'verificadores.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('lays out every page without overflowing', (tester) async {
      await tester.pumpWidget(const MyApp());

      for (final tab in ['UUID v4', 'CPF', 'CNPJ', 'Lorem']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Gerar'));
        await tester.pumpAndSettle();
        // pumpAndSettle rethrows the overflow assertion raised by a Row or
        // Column that does not fit, so reaching here means the page fits.
      }
    });

    testWidgets('the generate button keeps a single-line label', (
      tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.tap(find.text('Gerar'));
      await tester.pumpAndSettle();

      // "Gerar novo" is the longest label, and the one that used to collapse
      // into a column of single letters when the three actions shared a Row.
      final label = find.descendant(
        of: find.byType(FilledButton),
        matching: find.text('Gerar novo'),
      );
      final size = tester.getSize(label);

      expect(size.height, lessThan(32), reason: 'the label must not wrap');
      expect(size.width, greaterThan(size.height));
    });

    testWidgets('fits the narrowest phone still in use', (tester) async {
      // iPhone SE (1st gen) width: the tightest layout the app has to survive.
      _setSurface(const Size(320, 568));
      await tester.pumpWidget(const MyApp());
      await tester.tap(find.text('Gerar'));
      await tester.pumpAndSettle();

      final label = find.descendant(
        of: find.byType(FilledButton),
        matching: find.text('Gerar novo'),
      );
      expect(tester.getSize(label).height, lessThan(32));
    });
  });
}

/// Pins the test window to [size] for the duration of the test.
void _setSurface(Size size) {
  final view =
      TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!;
  view.devicePixelRatio = 1;
  view.physicalSize = size;
  addTearDown(view.resetPhysicalSize);
  addTearDown(view.resetDevicePixelRatio);
}
