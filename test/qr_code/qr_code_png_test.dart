import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/qr_code/data/qr_code_level.dart';
import 'package:fake_generator/qr_code/data/qr_code_png.dart';
import 'package:fake_generator/qr_code/data/qr_code_repository.dart';

import '../shared/png_decoder.dart';

void main() {
  group('encodeQrCodePng', () {
    final qrCode = QrCodeRepository().encode('HELLO WORLD', QrCodeLevel.medium);

    test('writes a 512×512 8-bit grayscale PNG', () {
      final png = encodeQrCodePng(qrCode);
      final header = ByteData.sublistView(png);

      expect(png.sublist(0, 8), [0x89, 0x50, 0x4E, 0x47, 13, 10, 26, 10]);
      expect(String.fromCharCodes(png.sublist(12, 16)), 'IHDR');
      expect(header.getUint32(16), 512);
      expect(header.getUint32(20), 512);
      expect(png[24], 8, reason: 'bit depth');
      expect(png[25], 0, reason: 'grayscale');
      expect(
        String.fromCharCodes(png.sublist(png.length - 8, png.length - 4)),
        'IEND',
      );
    });

    test('draws the modules black on white, quiet zone included', () {
      final pixels = decodePng(encodeQrCodePng(qrCode)).rows;
      // 21 modules + 8 of quiet zone: ~17.66 px per module.
      const module = 512 / 29;
      int at(int row, int column) =>
          pixels[(row * module + module / 2)
              .floor()][(column * module + module / 2).floor()];

      for (var row = 0; row < 29; row++) {
        for (var column = 0; column < 29; column++) {
          final inside = row >= 4 && row < 25 && column >= 4 && column < 25;
          final dark = inside && qrCode.isDark(row - 4, column - 4);
          expect(at(row, column), dark ? 0 : 255, reason: '($row, $column)');
        }
      }
    });

    test('uses only pure black and pure white', () {
      final pixels = decodePng(encodeQrCodePng(qrCode, size: 100)).rows;

      expect(pixels.expand((row) => row).toSet(), {0, 255});
    });
  });
}
