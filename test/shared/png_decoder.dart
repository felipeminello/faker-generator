import 'dart:io';
import 'dart:typed_data';

/// A decoded PNG: its size, bytes per pixel and the unfiltered pixel rows.
typedef DecodedPng = ({
  int width,
  int height,
  int channels,
  List<Uint8List> rows,
});

/// Decodes the PNGs `encodePng` writes: 8 bits per channel, grayscale or
/// RGB, no interlace, rows filtered with "None" or "Sub".
DecodedPng decodePng(Uint8List png) {
  final data = ByteData.sublistView(png);
  final idat = BytesBuilder();
  late int width, height, channels;

  var offset = 8;
  while (offset < png.length) {
    final length = data.getUint32(offset);
    final type = String.fromCharCodes(png.sublist(offset + 4, offset + 8));
    final body = offset + 8;
    if (type == 'IHDR') {
      width = data.getUint32(body);
      height = data.getUint32(body + 4);
      channels = switch (png[body + 9]) {
        0 => 1,
        2 => 3,
        final other => throw UnsupportedError('color type $other'),
      };
    } else if (type == 'IDAT') {
      idat.add(png.sublist(body, body + length));
    }
    offset += 12 + length;
  }

  final raw = zlib.decode(idat.takeBytes());
  final stride = width * channels;
  final rows = <Uint8List>[];
  for (var y = 0; y < height; y++) {
    final start = y * (stride + 1);
    final filter = raw[start];
    final row = Uint8List.fromList(raw.sublist(start + 1, start + 1 + stride));
    if (filter == 1) {
      for (var i = channels; i < stride; i++) {
        row[i] = (row[i] + row[i - channels]) & 0xFF;
      }
    } else if (filter != 0) {
      throw UnsupportedError('filter $filter');
    }
    rows.add(row);
  }
  return (width: width, height: height, channels: channels, rows: rows);
}
