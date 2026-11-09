import 'dart:io';
import 'dart:typed_data';

/// How the bytes handed to [encodePng] describe a pixel.
enum PngColor {
  /// One byte per pixel, 0 (black) to 255 (white).
  grayscale(1, 0),

  /// Three bytes per pixel: red, green, blue.
  rgb(3, 2);

  const PngColor(this.channels, this.colorType);

  /// Bytes per pixel.
  final int channels;

  /// The color type written in the IHDR chunk.
  final int colorType;
}

/// Encodes [pixels] — row-major, 8 bits per channel, no padding between
/// rows — as a [width]×[height] PNG.
///
/// Written by hand instead of through `dart:ui` so every pixel is exact and
/// it runs without a Flutter engine (in an isolate, or in plain Dart tests).
/// Every row uses the "Sub" filter (each byte minus the one a pixel to its
/// left), which turns flat areas and smooth gradients into runs of small
/// numbers that zlib packs far tighter than the raw bytes.
Uint8List encodePng({
  required int width,
  required int height,
  required Uint8List pixels,
  required PngColor color,
}) {
  final channels = color.channels;
  final stride = width * channels;
  assert(width > 0 && height > 0);
  assert(pixels.length == stride * height);

  final filtered = Uint8List((stride + 1) * height);
  var out = 0;
  for (var y = 0; y < height; y++) {
    final row = y * stride;
    filtered[out++] = 1; // filter type: Sub
    for (var i = 0; i < stride; i++) {
      final left = i < channels ? 0 : pixels[row + i - channels];
      filtered[out++] = (pixels[row + i] - left) & 0xFF;
    }
  }

  final header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, color.colorType)
    ..setUint8(10, 0) // compression: deflate
    ..setUint8(11, 0) // filter method
    ..setUint8(12, 0); // no interlace

  return (BytesBuilder(copy: false)
        ..add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        ..add(_chunk('IHDR', header.buffer.asUint8List()))
        ..add(_chunk('IDAT', zlib.encode(filtered)))
        ..add(_chunk('IEND', const [])))
      .takeBytes();
}

/// A PNG chunk: length, type, data and the CRC of type + data.
Uint8List _chunk(String type, List<int> data) {
  final chunk = Uint8List(12 + data.length);
  final view = ByteData.sublistView(chunk)..setUint32(0, data.length);
  chunk.setRange(4, 8, type.codeUnits);
  chunk.setRange(8, 8 + data.length, data);
  view.setUint32(8 + data.length, _crc32(chunk, 4, 8 + data.length));
  return chunk;
}

final _crcTable = Uint32List.fromList(
  List<int>.generate(256, (n) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = c & 1 == 1 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    return c;
  }),
);

/// CRC-32 of `bytes[start..end)`.
int _crc32(Uint8List bytes, int start, int end) {
  var crc = 0xFFFFFFFF;
  for (var i = start; i < end; i++) {
    crc = _crcTable[(crc ^ bytes[i]) & 0xFF] ^ (crc >> 8);
  }
  return crc ^ 0xFFFFFFFF;
}
