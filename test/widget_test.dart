// Widget tests for the generator app shell and the feature pages.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/main.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  // The password page keeps its history with shared_preferences, whose
  // plugin is not registered in widget tests.
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

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

  testWidgets('generates a 16-character password by default', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Senha'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma senha gerada ainda'), findsOneWidget);

    await tester.tap(find.text('Gerar'));
    await tester.pumpAndSettle();

    expect(_shownPassword(tester), hasLength(16));
    expect(find.text('Gerar nova'), findsOneWidget);
  });

  testWidgets('leaves out special characters once they are unchecked', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Senha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gerar'));
    await tester.pumpAndSettle();

    final symbols = find.text('Caracteres especiais');
    await tester.ensureVisible(symbols);
    await tester.tap(symbols);
    await tester.pumpAndSettle();

    // The password on screen is regenerated with the new options.
    expect(_shownPassword(tester), matches(RegExp(r'^[A-Za-z0-9]{16}$')));
    expect(find.text('Restaurar padrão'), findsNothing);
  });

  testWidgets('lists the generated passwords under Recentes', (tester) async {
    final clipboard = _mockClipboard(tester);
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Senha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gerar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gerar nova'));
    await tester.pumpAndSettle();
    final latest = _shownPassword(tester);

    await tester.tap(find.text('Recentes'));
    await tester.pumpAndSettle();

    final entries = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(ListTile),
    );
    expect(entries, findsNWidgets(2));
    expect(
      find.descendant(of: entries.first, matching: find.text(latest)),
      findsOneWidget,
      reason: 'the newest password comes first',
    );

    // Picking one copies it and closes the list.
    await tester.tap(entries.first);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(clipboard, [latest]);
    expect(find.text('Copiado para a área de transferência'), findsOneWidget);
  });

  testWidgets('explains a cron expression as it is typed', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Cron'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma expressão ainda'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '*/15 9-17 * * 1-5');
    await tester.pumpAndSettle();

    expect(
      find.text(
        '“A cada 15 minutos nas horas de 9 a 17, de segunda-feira a '
        'sexta-feira.”',
      ),
      findsOneWidget,
    );
    expect(find.text('Próximas execuções'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '*/15 25 * * 1-5');
    await tester.pumpAndSettle();

    expect(
      find.text('25 está fora do intervalo de hora: 0-23.'),
      findsOneWidget,
    );
    expect(find.text('Próximas execuções'), findsNothing);
  });

  testWidgets('generates, then clears, a random cron expression', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Cron'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gerar'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text.split(' '), hasLength(5));
    expect(find.text('Gerar nova'), findsOneWidget);
    expect(find.text('Nenhuma expressão ainda'), findsNothing);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(field.controller!.text, isEmpty);
    expect(find.text('Nenhuma expressão ainda'), findsOneWidget);
  });

  testWidgets('uses a cron example picked from the list', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Cron'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Exemplos'));
    await tester.pumpAndSettle();
    final example = find.text('Dias úteis às 9h');
    await tester.scrollUntilVisible(
      example,
      100,
      scrollable: find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(example);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(find.widgetWithText(TextField, '0 9 * * 1-5'), findsOneWidget);
    expect(
      find.text('“Às 09:00, de segunda-feira a sexta-feira.”'),
      findsOneWidget,
    );
  });

  testWidgets('spaces out cron fields typed or pasted together', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Cron'));
    await tester.pumpAndSettle();
    final field = find.byType(TextField);
    TextEditingController controller() =>
        tester.widget<TextField>(field).controller!;

    // Typed one character at a time, at the end.
    for (final char in '*/5****'.split('')) {
      await tester.enterText(field, controller().text + char);
    }
    await tester.pumpAndSettle();

    expect(controller().text, '*/5 * * * *');
    expect(find.text('“A cada 5 minutos.”'), findsOneWidget);

    // Pasted.
    await tester.enterText(field, '0 9**1-5');
    await tester.pumpAndSettle();

    expect(controller().text, '0 9 * * 1-5');
  });

  testWidgets('a cron field typed in front of another keeps growing', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Cron'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '* * * * *');
    await tester.pumpAndSettle();
    final controller = tester
        .widget<TextField>(find.byType(TextField))
        .controller!;

    // "1" typed at the start: the space goes in, the cursor stays before it.
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '1* * * * *',
        selection: TextSelection.collapsed(offset: 1),
      ),
    );
    await tester.pump();

    expect(controller.text, '1 * * * * *');
    expect(controller.selection, const TextSelection.collapsed(offset: 1));

    // So the "5" typed next joins the same field.
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '15 * * * * *',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pump();

    expect(controller.text, '15 * * * * *');
  });

  testWidgets('shows the values of the cron field being edited', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Cron'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '5 4 * * *');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'hora'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.selection.textInside('5 4 * * *'), '4');
    expect(find.text('Referência · hora'), findsOneWidget);
    expect(find.text('0-23'), findsOneWidget);
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

      for (final tab in ['UUID v4', 'CPF', 'CNPJ', 'Lorem', 'Senha', 'Cron']) {
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

    testWidgets('shows the recent passwords in a bottom sheet', (tester) async {
      _setSurface(const Size(320, 568));
      await tester.pumpWidget(const MyApp());
      await tester.tap(find.text('Senha'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gerar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Recentes'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text(_shownPassword(tester)),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Nenhuma senha gerada ainda'),
        ),
        findsOneWidget,
      );
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

/// Answers the clipboard channel, which has no platform behind it in tests
/// (a copy would never complete), and returns the texts copied.
List<String> _mockClipboard(WidgetTester tester) {
  final copied = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return copied;
}

/// The password shown on the password page.
String _shownPassword(WidgetTester tester) =>
    tester.widget<SelectableText>(find.byType(SelectableText)).data!;

/// Pins the test window to [size] for the duration of the test.
void _setSurface(Size size) {
  final view =
      TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!;
  view.devicePixelRatio = 1;
  view.physicalSize = size;
  addTearDown(view.resetPhysicalSize);
  addTearDown(view.resetDevicePixelRatio);
}
