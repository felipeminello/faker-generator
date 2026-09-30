import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:qr/qr.dart';

import 'qr_code_level.dart';
import 'qr_code_model.dart';

/// Encodes text into QR Codes and makes up sample contents to encode.
class QrCodeRepository {
  QrCodeRepository({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  /// Encodes [text] at [level], in the smallest version it fits.
  ///
  /// Throws a [QrCodeTooLongException] when it does not fit even in
  /// version 40.
  QrCodeModel encode(String text, QrCodeLevel level) {
    final QrCode code;
    try {
      code = QrCode(payload: _payload(text), errorCorrectLevel: level.qrLevel);
    } on InputTooLongException {
      throw QrCodeTooLongException(level);
    }

    final image = QrImage(code);
    final size = image.moduleCount;
    return QrCodeModel(
      text: text,
      level: level,
      version: image.typeNumber,
      modules: [
        for (var row = 0; row < size; row++)
          for (var column = 0; column < size; column++)
            image.isDark(row, column),
      ],
    );
  }

  /// ASCII text is left to the `qr` package, which packs digits-only and
  /// upper-case text tighter. Anything else is written as UTF-8 behind an
  /// ECI header saying so: the package only adds that header for characters
  /// above U+00FF, so "ç" or "ã" would otherwise be read as Latin-1 ("Ã§").
  QrPayload _payload(String text) {
    if (text.codeUnits.every((unit) => unit < 0x80)) {
      return QrPayload.fromString(text);
    }
    return QrPayload()
      ..addECI(QrEciValue.utf8)
      ..addTypedData(Uint8List.fromList(utf8.encode(text)));
  }

  /// A made-up content of the kinds QR Codes usually carry: a link, Wi-Fi
  /// credentials, an e-mail address, a phone number or plain text.
  String random() => switch (_random.nextInt(5)) {
    0 => 'https://exemplo.com.br/${_chars(_lower, 8)}',
    1 =>
      'WIFI:T:WPA;S:Rede-${_chars(_digits, 4)};P:${_chars(_alphanumeric, 12)};;',
    2 => 'mailto:usuario${_chars(_digits, 3)}@exemplo.com.br',
    3 => 'tel:+55119${_chars(_digits, 8)}',
    _ => 'Pedido nº ${_chars(_digits, 6)} — obrigado pela preferência!',
  };

  static const _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const _digits = '0123456789';
  static const _alphanumeric =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  String _chars(String alphabet, int length) => String.fromCharCodes([
    for (var i = 0; i < length; i++)
      alphabet.codeUnitAt(_random.nextInt(alphabet.length)),
  ]);
}
