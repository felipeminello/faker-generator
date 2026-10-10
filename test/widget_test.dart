// Widget tests for the generator app shell and the feature pages.

import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
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

  testWidgets('starts on the CPF page in the empty state', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Massa de Teste'), findsOneWidget);
    expect(find.text('CPF'), findsWidgets);
    expect(find.text('Nenhum valor gerado ainda'), findsOneWidget);
  });

  testWidgets('generating a UUID replaces the empty state', (tester) async {
    await tester.pumpWidget(const MyApp());
    await _open(tester, 'UUID v4');

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
    await _open(tester, 'UUID v4');

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

    await _open(tester, 'Lorem');

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

    await _open(tester, 'Lorem');
    await tester.tap(find.text('Palavras'));
    await tester.pumpAndSettle();

    expect(find.text('Quantidade de palavras'), findsOneWidget);
    expect(find.widgetWithText(TextField, '50'), findsOneWidget);
  });

  testWidgets('generates a 16-character password by default', (tester) async {
    await tester.pumpWidget(const MyApp());

    await _open(tester, 'Senha');

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
    await _open(tester, 'Senha');
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
    await _open(tester, 'Senha');
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
    await _open(tester, 'Cron');

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
    await _open(tester, 'Cron');

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
    await _open(tester, 'Cron');

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
    await _open(tester, 'Cron');
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
    await _open(tester, 'Cron');
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
    await _open(tester, 'Cron');
    await tester.enterText(find.byType(TextField), '5 4 * * *');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'hora'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.selection.textInside('5 4 * * *'), '4');
    expect(find.text('Referência · hora'), findsOneWidget);
    expect(find.text('0-23'), findsOneWidget);
  });

  testWidgets('draws a QR Code for the typed text', (tester) async {
    await tester.pumpWidget(const MyApp());
    await _open(tester, 'QR Code');

    expect(find.text('Nenhum QR Code ainda'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'HELLO WORLD');
    await tester.pumpAndSettle();

    expect(find.text('Nenhum QR Code ainda'), findsNothing);
    expect(find.bySemanticsLabel('QR Code de: HELLO WORLD'), findsOneWidget);
    expect(find.text('Versão 1 · 21×21 módulos · 11 bytes'), findsOneWidget);

    await tester.tap(find.text('H'));
    await tester.pumpAndSettle();

    expect(find.text('Versão 2 · 25×25 módulos · 11 bytes'), findsOneWidget);
  });

  testWidgets('generates, then clears, a sample QR Code content', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await _open(tester, 'QR Code');

    await tester.tap(find.text('Gerar'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isNotEmpty);
    expect(find.text('Gerar outro'), findsOneWidget);
    expect(find.textContaining('módulos'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(field.controller!.text, isEmpty);
    expect(find.text('Nenhum QR Code ainda'), findsOneWidget);
  });

  testWidgets('downloads the QR Code as a PNG instead of copying it', (
    tester,
  ) async {
    final dialog = _FakeFilePicker();
    FilePickerPlatform.instance = dialog;
    await tester.pumpWidget(const MyApp());
    await _open(tester, 'QR Code');

    expect(find.text('Copiar'), findsNothing);
    final download = find.widgetWithText(OutlinedButton, 'Download');
    expect(tester.widget<OutlinedButton>(download).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'HELLO WORLD');
    await tester.pumpAndSettle();
    await tester.tap(download);
    await tester.pumpAndSettle();

    expect(dialog.saved.single.fileName, 'qrcode.png');
    expect(dialog.saved.single.mimeType, 'image/png');
    expect(
      find.text('QR Code salvo em ${Uri.file('/tmp/qrcode.png').toFilePath()}'),
      findsOneWidget,
    );
  });

  testWidgets('navigates between generator features', (tester) async {
    await tester.pumpWidget(const MyApp());

    await _open(tester, 'CNPJ');

    expect(
      find.textContaining('Cadastro Nacional da Pessoa Jurídica'),
      findsOneWidget,
    );
  });

  testWidgets('generates a list of CPFs from the chosen state', (tester) async {
    final clipboard = _mockClipboard(tester);
    await tester.pumpWidget(const MyApp());

    await tester.enterText(
      find.widgetWithText(TextField, 'Quantidade de CPFs'),
      '3',
    );
    await tester.tap(find.text('Qualquer estado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AC · Acre').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gerar'));
    await tester.pumpAndSettle();

    final cpfs = RegExp(r'^\d{3}\.\d{3}\.\d{2}2-\d{2}$');
    final rows = find.byWidgetPredicate(
      (widget) => widget is Text && cpfs.hasMatch(widget.data ?? ''),
    );
    expect(rows, findsNWidgets(3));
    expect(find.text('Gerar novos'), findsOneWidget);
    expect(
      find.text('9º dígito 2: região fiscal de AC, AM, AP, PA, RO e RR'),
      findsOneWidget,
    );

    await tester.tap(find.text('Copiar'));
    await tester.pumpAndSettle();

    expect(clipboard.single.split('\n'), hasLength(3));

    await tester.tap(find.text('Com pontuação'));
    await tester.pumpAndSettle();

    expect(rows, findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            RegExp(r'^\d{8}2\d{2}$').hasMatch(widget.data ?? ''),
      ),
      findsNWidgets(3),
    );
  });

  testWidgets('generates an alphanumeric CNPJ', (tester) async {
    await tester.pumpWidget(const MyApp());
    await _open(tester, 'CNPJ');

    await tester.tap(find.text('Alfanumérico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gerar'));
    await tester.pumpAndSettle();

    final value = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(
      value.data,
      matches(RegExp(r'^[0-9A-Z]{2}\.[0-9A-Z]{3}\.[0-9A-Z]{3}/0001-\d{2}$')),
    );
    expect(value.data, matches(RegExp('[A-Z]')));
  });

  testWidgets('exports the CPF list as CSV', (tester) async {
    final dialog = _FakeFilePicker();
    FilePickerPlatform.instance = dialog;
    await tester.pumpWidget(const MyApp());

    final export = find.widgetWithText(OutlinedButton, 'Exportar');
    expect(tester.widget<OutlinedButton>(export).onPressed, isNull);

    await tester.tap(find.text('Gerar'));
    await tester.pumpAndSettle();
    await tester.tap(export);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('CSV'));
    await tester.pumpAndSettle();

    expect(dialog.saved.single.fileName, 'cpfs.csv');
    expect(dialog.saved.single.mimeType, 'text/csv');
    expect(
      String.fromCharCodes(dialog.saved.single.bytes),
      matches(RegExp(r'^cpf\n\d{3}\.\d{3}\.\d{3}-\d{2}\n$')),
    );
    expect(
      find.text('Lista salva em ${Uri.file('/tmp/cpfs.csv').toFilePath()}'),
      findsOneWidget,
    );
  });

  testWidgets('validates CPFs and CNPJs as they are typed', (tester) async {
    // Tall enough for both verdicts to be on screen.
    _setSurface(const Size(800, 1000));
    await tester.pumpWidget(const MyApp());
    await _open(tester, 'Validar');

    expect(find.text('Nenhum valor para validar ainda'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      '123.456.789-00\n12.abc.345/01de-35',
    );
    await tester.pumpAndSettle();

    expect(find.text('CPF inválido'), findsOneWidget);
    expect(find.text('Com os dígitos certos: 123.456.789-09'), findsOneWidget);
    expect(find.text('CNPJ válido'), findsOneWidget);
    expect(find.text('12.ABC.345/01DE-35'), findsOneWidget);
    expect(find.text('1 válido'), findsOneWidget);
    expect(find.text('1 inválido'), findsOneWidget);
  });

  testWidgets('validates the example, then what is pasted', (tester) async {
    _mockClipboard(tester, paste: '11.222.333/0001-81');
    await tester.pumpWidget(const MyApp());
    await _open(tester, 'Validar');

    await tester.tap(find.text('Ver exemplo'));
    await tester.pumpAndSettle();

    expect(find.text('3 válidos'), findsOneWidget);
    expect(find.text('3 inválidos'), findsOneWidget);

    await tester.tap(find.text('Colar'));
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(TextField, '11.222.333/0001-81'),
      findsOneWidget,
    );
    expect(find.text('CNPJ válido'), findsOneWidget);
    expect(find.text('Numérico · Matriz · Raiz 11.222.333'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum valor para validar ainda'), findsOneWidget);
  });

  testWidgets(
    'a tap outside a text field puts the keyboard away',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await _open(tester, 'Validar');
      await tester.tap(find.byType(TextField));
      await tester.pump();

      expect(tester.testTextInput.isVisible, isTrue);

      await tester.tap(find.text('Validar CPF e CNPJ'));
      await tester.pump();

      expect(tester.testTextInput.isVisible, isFalse);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).focusNode,
        isNot(predicate<FocusNode>((node) => node.hasFocus)),
      );
    },
    // Flutter already does this for a mouse click; the touch of a phone is
    // what needs the override in main.dart.
    variant: TargetPlatformVariant.mobile(),
  );

  testWidgets('a wide window lists every tool by section', (tester) async {
    _setSurface(const Size(1280, 800));
    await tester.pumpWidget(const MyApp());

    expect(find.byType(NavigationDrawer), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    for (final section in [
      'Documentos',
      'Desenvolvimento',
      'Outras ferramentas',
    ]) {
      expect(find.text(section), findsOneWidget);
    }

    await tester.tap(find.text('Cron'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma expressão ainda'), findsOneWidget);
  });

  group('phone-sized window', () {
    // Roughly an iPhone 15 in logical pixels.
    setUp(() => _setSurface(const Size(393, 852)));

    testWidgets('keeps the documents in a bottom bar', (tester) async {
      await tester.pumpWidget(const MyApp());

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(NavigationDrawer), findsNothing);
      for (final label in ['CPF', 'CNPJ', 'Validar', 'Mais']) {
        expect(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(label),
          ),
          findsOneWidget,
        );
      }
    });

    testWidgets('navigates from the bottom bar', (tester) async {
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.text('CNPJ'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Cadastro Nacional da Pessoa Jurídica'),
        findsOneWidget,
      );
    });

    testWidgets('opens the other tools from "Mais"', (tester) async {
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.text('Mais'));
      await tester.pumpAndSettle();

      expect(find.text('Desenvolvimento'), findsOneWidget);
      expect(find.text('Outras ferramentas'), findsOneWidget);

      await tester.tap(find.text('Cron'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Nenhuma expressão ainda'), findsOneWidget);
    });

    testWidgets('keeps the bottom bar above the keyboard', (tester) async {
      await tester.pumpWidget(const MyApp());
      await _openOnPhone(tester, 'Validar');
      await tester.tap(find.byType(TextField));
      _showKeyboard(tester, height: 336);
      await tester.pumpAndSettle();

      expect(tester.getRect(find.byType(NavigationBar)).bottom, 852 - 336);

      // The page can be left while typing.
      await _openOnPhone(tester, 'CPF');

      expect(find.text('Nenhum valor gerado ainda'), findsOneWidget);
    });

    testWidgets('fits every page with a text field above the keyboard', (
      tester,
    ) async {
      // iPhone SE (2nd and 3rd gen): the shortest screen left once the
      // keyboard and the bottom bar are both up.
      _setSurface(const Size(375, 667));
      _showKeyboard(tester, height: 260);
      await tester.pumpWidget(const MyApp());

      for (final tool in [
        'CPF',
        'CNPJ',
        'Validar',
        'Cron',
        'Lorem',
        'QR Code',
      ]) {
        await _openOnPhone(tester, tool);
        final field = find.byType(TextField).first;
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        await tester.tap(field);
        // pumpAndSettle rethrows the overflow assertion, as above.
        await tester.pumpAndSettle();
      }
    });

    testWidgets('lays out every page without overflowing', (tester) async {
      await tester.pumpWidget(const MyApp());

      for (final tool in [
        'CPF',
        'CNPJ',
        'Validar',
        'UUID v4',
        'Cron',
        'Lorem',
        'Senha',
        'QR Code',
      ]) {
        await _openOnPhone(tester, tool);
        await tester.tap(
          find.text(tool == 'Validar' ? 'Ver exemplo' : 'Gerar'),
        );
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
      await _openOnPhone(tester, 'Senha');
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
      // The QR Code page is the tallest: the code alone is as wide as the
      // screen.
      await _openOnPhone(tester, 'QR Code');
      await tester.tap(find.text('Gerar'));
      await tester.pumpAndSettle();
      // The CNPJ page has the most actions: Gerar, Copiar, Exportar, Limpar.
      await _openOnPhone(tester, 'CNPJ');
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

/// Opens [tool] from the side navigation of a wide window. The rail scrolls
/// when the window is too short for every tool.
Future<void> _open(WidgetTester tester, String tool) async {
  final entry = find.descendant(
    of: find.byType(NavigationRail),
    matching: find.text(tool),
  );
  await tester.ensureVisible(entry);
  await tester.pumpAndSettle();
  await tester.tap(entry);
  await tester.pumpAndSettle();
}

/// Opens [tool] on a phone: straight from the bottom bar, or through "Mais".
Future<void> _openOnPhone(WidgetTester tester, String tool) async {
  final inBar = find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(tool),
  );
  if (tester.any(inBar)) {
    await tester.tap(inBar);
  } else {
    await tester.tap(find.text('Mais'));
    await tester.pumpAndSettle();
    final entry = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text(tool, skipOffstage: false),
    );
    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    await tester.tap(entry);
  }
  await tester.pumpAndSettle();
}

/// Stands in for the native "save as" dialog: records each save and answers
/// as if the user picked `/tmp/<suggested name>`.
class _FakeFilePicker extends FilePickerPlatform {
  final saved = <({String fileName, String mimeType, Uint8List bytes})>[];

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    saved.add((fileName: fileName, mimeType: mimeType, bytes: bytes));
    return Uri.file('/tmp/$fileName');
  }
}

/// Answers the clipboard channel, which has no platform behind it in tests
/// (a copy would never complete), and returns the texts copied. A paste
/// reads [paste].
List<String> _mockClipboard(WidgetTester tester, {String? paste}) {
  final copied = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      if (call.method == 'Clipboard.getData' && paste != null) {
        return {'text': paste};
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

/// Stands in for an on-screen keyboard [height] logical pixels tall, up for
/// the rest of the test.
void _showKeyboard(WidgetTester tester, {required double height}) {
  tester.view.viewInsets = FakeViewPadding(
    bottom: height * tester.view.devicePixelRatio,
  );
  addTearDown(tester.view.resetViewInsets);
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
