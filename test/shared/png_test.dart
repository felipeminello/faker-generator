import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/shared/data/png.dart';

import 'png_decoder.dart';

void main() {
  group('encodePng', () {
    test('writes the signature, IHDR and IEND', () {
      final png = encodePng(
        width: 3,
        height: 2,
        pixels: Uint8List(18),
        color: PngColor.rgb,
      );
      final header = ByteData.sublistView(png);

      expect(png.sublist(0, 8), [0x89, 0x50, 0x4E, 0x47, 13, 10, 26, 10]);
      expect(String.fromCharCodes(png.sublist(12, 16)), 'IHDR');
      expect([header.getUint32(16), header.getUint32(20)], [3, 2]);
      expect(png[24], 8, reason: 'bit depth');
      expect(png[25], 2, reason: 'truecolor');
      expect(
        String.fromCharCodes(png.sublist(png.length - 8, png.length - 4)),
        'IEND',
      );
      // CRC-32 of "IEND" with no data, from the PNG specification.
      expect(header.getUint32(png.length - 4), 0xAE426082);
    });

    test('round-trips RGB pixels through the Sub filter', () {
      final pixels = Uint8List.fromList([
        255, 0, 0, 0, 255, 0, 0, 0, 255, //
        10, 20, 30, 5, 250, 3, 255, 255, 255,
      ]);
      final decoded = decodePng(
        encodePng(width: 3, height: 2, pixels: pixels, color: PngColor.rgb),
      );

      expect(decoded.channels, 3);
      expect(decoded.rows.expand((row) => row), pixels);
    });

    test('round-trips grayscale pixels', () {
      final pixels = Uint8List.fromList([0, 128, 255, 7]);
      final decoded = decodePng(
        encodePng(
          width: 2,
          height: 2,
          pixels: pixels,
          color: PngColor.grayscale,
        ),
      );

      expect(decoded.channels, 1);
      expect(decoded.rows.expand((row) => row), pixels);
    });
  });
}
