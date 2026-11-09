import 'dart:typed_data';

import '../../shared/data/png.dart';
import 'qr_code_model.dart';

/// Blank modules on each side of the code, as the QR Code standard asks.
const qrCodeQuietZone = 4;

/// Encodes [qrCode] as a [size]×[size] PNG, black on white with the quiet
/// zone around it.
///
/// Every pixel is exact (no anti-aliasing). Modules are mapped to pixels by
/// rounding, so with 512 px and, say, 29 + 8 modules some modules are one
/// pixel wider than others — scanners do not mind.
Uint8List encodeQrCodePng(QrCodeModel qrCode, {int size = 512}) {
  final count = qrCode.size;
  final total = count + 2 * qrCodeQuietZone;

  // Which module each pixel column (and row) falls in, quiet zone included.
  final moduleAt = [for (var p = 0; p < size; p++) p * total ~/ size];

  final pixels = Uint8List(size * size);
  var offset = 0;
  for (var y = 0; y < size; y++) {
    final row = moduleAt[y] - qrCodeQuietZone;
    for (var x = 0; x < size; x++) {
      final column = moduleAt[x] - qrCodeQuietZone;
      final dark =
          row >= 0 &&
          row < count &&
          column >= 0 &&
          column < count &&
          qrCode.isDark(row, column);
      pixels[offset++] = dark ? 0x00 : 0xFF;
    }
  }

  return encodePng(
    width: size,
    height: size,
    pixels: pixels,
    color: PngColor.grayscale,
  );
}
