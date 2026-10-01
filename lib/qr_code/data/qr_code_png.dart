import 'dart:io';
import 'dart:typed_data';

import 'qr_code_model.dart';

/// Blank modules on each side of the code, as the QR Code standard asks.
const qrCodeQuietZone = 4;

/// Encodes [qrCode] as a [size]×[size] PNG, black on white with the quiet
/// zone around it.
///
/// Written by hand instead of through `dart:ui` so every pixel is exact (no
/// anti-aliasing) and it runs without a Flutter engine. Modules are mapped to
/// pixels by rounding, so with 512 px and, say, 29 + 8 modules some modules
/// are one pixel wider than others — scanners do not mind.
Uint8List encodeQrCodePng(QrCodeModel qrCode, {int size = 512}) {
  final count = qrCode.size;
  final total = count + 2 * qrCodeQuietZone;

  // Which module each pixel column (and row) falls in, quiet zone included.
  final moduleAt = [for (var p = 0; p < size; p++) p * total ~/ size];

  // 8-bit grayscale scanlines, each preceded by filter type 0 (none).
  final raw = Uint8List((size + 1) * size);
  var offset = 0;
  for (var y = 0; y < size; y++) {
    raw[offset++] = 0;
    final row = moduleAt[y] - qrCodeQuietZone;
    for (var x = 0; x < size; x++) {
      final column = moduleAt[x] - qrCodeQuietZone;
      final dark =
          row >= 0 &&
          row < count &&
          column >= 0 &&
          column < count &&
          qrCode.isDark(row, column);
      raw[offset++] = dark ? 0x00 : 0xFF;
    }
  }

  final header = ByteData(13)
    ..setUint32(0, size)
    ..setUint32(4, size)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, 0) // color type: grayscale
    ..setUint8(10, 0) // compression: deflate
    ..setUint8(11, 0) // filter method
    ..setUint8(12, 0); // no interlace

  return (BytesBuilder(copy: false)
        ..add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        ..add(_chunk('IHDR', header.buffer.asUint8List()))
        ..add(_chunk('IDAT', zlib.encode(raw)))
        ..add(_chunk('IEND', const [])))
      .takeBytes();
}

/// A PNG chunk: length, type, data and the CRC of type + data.
List<int> _chunk(String type, List<int> data) {
  final body = [...type.codeUnits, ...data];
  final length = ByteData(4)..setUint32(0, data.length);
  final crc = ByteData(4)..setUint32(0, _crc32(body));
  return [...length.buffer.asUint8List(), ...body, ...crc.buffer.asUint8List()];
}

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = c & 1 == 1 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final byte in bytes) {
    crc = _crcTable[(crc ^ byte) & 0xFF] ^ (crc >> 8);
  }
  return crc ^ 0xFFFFFFFF;
}
