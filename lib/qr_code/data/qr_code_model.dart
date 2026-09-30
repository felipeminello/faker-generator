import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'qr_code_level.dart';

/// Immutable representation of an encoded QR Code: the text it holds and the
/// grid of modules (the black and white squares) to draw.
class QrCodeModel {
  QrCodeModel({
    required this.text,
    required this.level,
    required this.version,
    required List<bool> modules,
  }) : modules = List.unmodifiable(modules),
       assert(modules.length == (version * 4 + 17) * (version * 4 + 17));

  /// The encoded text.
  final String text;

  /// The error correction level it was encoded with.
  final QrCodeLevel level;

  /// The QR Code version (1-40), which sets its size.
  final int version;

  /// Row-major grid of [size]×[size] modules; `true` is a dark module.
  /// The quiet zone around the code is not included.
  final List<bool> modules;

  /// Modules per side: 21 for version 1, up to 177 for version 40.
  int get size => version * 4 + 17;

  /// How many bytes [text] takes as UTF-8, which is what the capacity of a
  /// QR Code is measured in.
  int get byteCount => utf8.encode(text).length;

  /// Whether the module at [row], [column] is dark.
  bool isDark(int row, int column) => modules[row * size + column];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QrCodeModel &&
          other.text == text &&
          other.level == level &&
          other.version == version &&
          listEquals(other.modules, modules));

  @override
  int get hashCode =>
      Object.hash(text, level, version, Object.hashAll(modules));

  @override
  String toString() => 'QrCodeModel("$text", ${level.label}, v$version)';
}

/// Thrown when the text does not fit in a QR Code at the chosen level.
class QrCodeTooLongException implements Exception {
  const QrCodeTooLongException(this.level);

  /// The level the text was too long for.
  final QrCodeLevel level;

  /// Portuguese explanation shown in place of the code.
  String get message {
    final limit =
        'até ${_thousands(level.maxBytes)} bytes no nível ${level.label}';
    return level == QrCodeLevel.low
        ? 'Texto longo demais para um QR Code ($limit).'
        : 'Texto longo demais para um QR Code ($limit). '
              'Encurte o texto ou escolha um nível de correção menor.';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QrCodeTooLongException && other.level == level);

  @override
  int get hashCode => level.hashCode;

  @override
  String toString() => 'QrCodeTooLongException(${level.label})';
}

/// 2953 → "2.953", the Brazilian thousands separator.
String _thousands(int value) =>
    value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => '.');
