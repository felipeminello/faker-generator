// Monta as telas das capturas da App Store, num simulador iOS ou no Mac. Rode
// com `python tool/store_media/capture.py`, que lê os marcadores @@ impressos
// aqui e tira as capturas.
//
// O histórico de senhas fica em memória, então nada do aparelho aparece em
// Recentes e nada é gravado nele.
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:fake_generator/cnpj/bloc/cnpj_bloc.dart';
import 'package:fake_generator/cnpj/data/cnpj_kind.dart';
import 'package:fake_generator/cnpj/data/cnpj_repository.dart';
import 'package:fake_generator/cpf/bloc/cpf_bloc.dart';
import 'package:fake_generator/cpf/data/uf.dart';
import 'package:fake_generator/cron/bloc/cron_bloc.dart';
import 'package:fake_generator/home/presentation/home_page.dart';
import 'package:fake_generator/main.dart';
import 'package:fake_generator/qr_code/bloc/qr_code_bloc.dart';
import 'package:fake_generator/validator/bloc/validator_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Cenas a rodar, separadas por vírgula; todas quando vazio.
const _scenes = String.fromEnvironment('SCENE');

/// No macOS o app é desenhado fora da tela, no tamanho e na escala de uma
/// janela Retina, e as capturas saem da árvore de renderização.
const _mac = bool.fromEnvironment('MAC');
const _macWindow = Size(1040, 680);
final _macBoundary = GlobalKey();

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  void scene(String name, Future<void> Function(_Director d) body) {
    testWidgets(
      name,
      skip: _scenes.isNotEmpty && !_scenes.split(',').contains(name),
      timeout: const Timeout(Duration(minutes: 5)),
      (tester) => body(_Director(tester)),
    );
  }

  scene('screenshots', (d) async {
    await d.start();

    // O seletor de estado aberto, antes de gerar: depois, a página rola até
    // a lista e o seletor sai de vista.
    d.bloc<CpfBloc>()
      ..add(const CpfCountChanged(10))
      ..add(const CpfUfChanged(Uf.sp));
    await d.pause(500);
    await d.tap(find.text('SP · São Paulo'));
    await d.shot('02_cpf_estado');
    await d.tap(find.text('SP · São Paulo').last);

    await d.tap(find.text('Gerar'));
    await d.shot('01_cpf');

    await d.open('CNPJ');
    d.bloc<CnpjBloc>()
      ..add(const CnpjKindChanged(CnpjKind.alphanumeric))
      ..add(const CnpjCountChanged(10));
    await d.tap(find.text('Gerar'));
    await d.shot('03_cnpj');

    await d.tap(find.text('Exportar'));
    await d.shot('04_exportar');
    await d.tap(find.text('Exportar'));

    await d.open('Validar');
    await d.tap(find.text('Ver exemplo'));
    await d.shot('05_validar');

    d.bloc<ValidatorBloc>().add(ValidatorTextChanged(_pastedJson()));
    await d.shot('06_validar_lista');

    await d.open('Cron');
    d.bloc<CronBloc>().add(const CronExpressionChanged('*/15 9-17 * * 1-5'));
    await d.shot('07_cron');

    await d.open('UUID v4');
    await d.tap(find.text('Gerar'));
    await d.shot('08_uuid');

    await d.open('Lorem');
    await d.tap(find.text('Gerar'));
    await d.shot('09_lorem');

    await d.open('QR Code');
    d.bloc<QrCodeBloc>().add(const QrCodeTextChanged('https://minello.dev.br'));
    await d.shot('10_qr_code');
  });
}

/// Uma lista JSON como a que se cola de uma fixture: CNPJs alfanuméricos
/// válidos, um numérico e, em segundo, um com o dígito verificador errado.
String _pastedJson() {
  final cnpjs = CnpjRepository(
    random: Random(2026),
  ).generateMany(3, kind: CnpjKind.alphanumeric, headOffice: false);
  final typo = cnpjs[1].formatted;
  final wrongDigit = (int.parse(typo[typo.length - 1]) + 1) % 10;
  return const JsonEncoder.withIndent('  ').convert([
    cnpjs[0].formatted,
    '${typo.substring(0, typo.length - 1)}$wrongDigit',
    '11.222.333/0001-81',
    cnpjs[2].formatted,
  ]);
}

/// Interações roteirizadas e os marcadores que o script de captura lê.
class _Director {
  _Director(this.tester);

  final WidgetTester tester;

  /// Abre o app do zero, na primeira aba, com o histórico de senhas vazio.
  Future<void> start() async {
    if (_mac) {
      tester.view
        ..devicePixelRatio = 2
        ..physicalSize = _macWindow * 2;
    }
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await tester.pumpWidget(
      RepaintBoundary(
        key: _macBoundary,
        child: MyApp(key: UniqueKey()),
      ),
    );
    await pause(1500);
  }

  /// O Bloc de uma funcionalidade, para escrever no campo de texto sem
  /// teclado na tela.
  T bloc<T extends BlocBase<Object?>>() =>
      tester.element(find.byType(HomePage)).read<T>();

  /// Abre uma ferramenta: pela barra de baixo ou pelo "Mais", no iPhone;
  /// pelo painel lateral, no iPad e no Mac.
  Future<void> open(String tool) async {
    final bar = find.byType(NavigationBar);
    if (!tester.any(bar)) {
      await tap(
        find.descendant(
          of: find.byType(NavigationDrawer),
          matching: find.text(tool),
        ),
      );
      return;
    }
    final inBar = find.descendant(of: bar, matching: find.text(tool));
    if (tester.any(inBar)) {
      await tap(inBar);
      return;
    }
    await tap(find.text('Mais'));
    await tap(
      find.descendant(of: find.byType(BottomSheet), matching: find.text(tool)),
    );
  }

  Future<void> pause(int ms) async {
    await tester.pump();
    await Future<void>.delayed(Duration(milliseconds: ms));
  }

  static var _pointer = 1000;

  /// Toca como um dedo. [WidgetTester.tap] desenharia na tela a mira do
  /// binding de teste.
  Future<void> tap(Finder finder, {int after = 900}) async {
    final binding = tester.binding as LiveTestWidgetsFlutterBinding;
    final position = tester.getCenter(finder.first);
    final pointer = _pointer++;
    void send(PointerEvent event) => binding.handlePointerEventForSource(
      event,
      source: TestBindingEventSource.device,
    );
    binding.shouldPropagateDevicePointerEvents = true;
    try {
      send(PointerDownEvent(pointer: pointer, position: position));
      await Future<void>.delayed(const Duration(milliseconds: 90));
      send(PointerUpEvent(pointer: pointer, position: position));
    } finally {
      binding.shouldPropagateDevicePointerEvents = false;
    }
    await pause(after);
  }

  /// [settle] deixa as animações terminarem; o script de captura precisa da
  /// tela parada por um momento depois do marcador.
  Future<void> shot(String name, {int settle = 900}) async {
    await pause(settle);
    if (_mac) {
      final boundary =
          _macBoundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await tester.runAsync(
        () => boundary.toImage(pixelRatio: 2),
      );
      final bytes = await tester.runAsync(
        () => image!.toByteData(format: ui.ImageByteFormat.png),
      );
      // O sandbox deixa o arquivo fora do alcance do script de captura, então
      // o PNG vai pelo log, em linhas de base64.
      final encoded = base64Encode(bytes!.buffer.asUint8List());
      for (var i = 0; i < encoded.length; i += 4000) {
        _marker(
          'DATA $name ${encoded.substring(i, min(i + 4000, encoded.length))}',
        );
      }
      _marker('SHOT $name');
      await pause(300);
      return;
    }
    _marker('SHOT $name');
    await pause(2500);
  }

  void _marker(String text) {
    // ignore: avoid_print
    print('@@$text t=${DateTime.now().millisecondsSinceEpoch}');
  }
}
