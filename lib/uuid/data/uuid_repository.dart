import 'dart:math';

import 'uuid_model.dart';

/// Generates random version 4 (random) UUIDs as defined by RFC 4122.
class UuidRepository {
  UuidRepository({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  static const String _hexDigits = '0123456789abcdef';

  /// Returns a freshly generated UUID v4.
  UuidModel generate() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    // Set the version (4) and variant (10xx) bits per RFC 4122 section 4.4.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final buffer = StringBuffer();
    for (var i = 0; i < bytes.length; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) buffer.write('-');
      final byte = bytes[i];
      buffer
        ..write(_hexDigits[(byte >> 4) & 0x0f])
        ..write(_hexDigits[byte & 0x0f]);
    }

    return UuidModel(buffer.toString());
  }
}
