// Monta as telas das capturas da App Store, num simulador iOS ou no Mac. Rode
// com `python tool/store_media/capture.py`, que lê os marcadores @@ impressos
// aqui e tira as capturas.
//
// O histórico de senhas fica em memória, então nada do aparelho aparece em
// Recentes e nada é gravado nele.
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:fake_generator/cron/bloc/cron_bloc.dart';
import 'package:fake_generator/home/presentation/home_page.dart';
import 'package:fake_generator/main.dart';
import 'package:fake_generator/qr_code/bloc/qr_code_bloc.dart';
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

    await d.tap(find.text('Gerar'));
    await d.shot('01_uuid');

    await d.tap(find.text('CPF'));
    await d.tap(find.text('Gerar'));
    await d.shot('02_cpf');

    await d.tap(find.text('CNPJ'));
    await d.tap(find.text('Gerar'));
    await d.shot('03_cnpj');

    await d.tap(find.text('Lorem'));
    await d.tap(find.text('Gerar'));
    await d.shot('04_lorem');

    await d.tap(find.text('Senha'));
    await d.tap(find.text('Gerar'));
    await d.shot('05_senha');

    await d.tap(find.text('Cron'));
    d.bloc<CronBloc>().add(const CronExpressionChanged('*/15 9-17 * * 1-5'));
    await d.shot('06_cron');

    await d.tap(find.text('QR Code'));
    d.bloc<QrCodeBloc>().add(
      const QrCodeTextChanged('https://minello.dev.br'),
    );
    await d.shot('07_qr_code');
  });
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
