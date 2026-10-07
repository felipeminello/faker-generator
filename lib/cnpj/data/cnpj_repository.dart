import 'dart:math';

import 'cnpj_kind.dart';
import 'cnpj_model.dart';

/// Generates valid Brazilian CNPJ numbers (with correct check digits), in
/// the classic numeric format or the new alphanumeric one.
class CnpjRepository {
  CnpjRepository({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  /// Largest batch [generateMany] makes.
  static const maxCount = 1000;

  static const _digits = '0123456789';
  static const _alphanumeric = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  // Modulus 11 weights applied right-to-left across the base digits.
  static const List<int> _firstWeights = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  static const List<int> _secondWeights = [
    6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2, //
  ];

  /// Returns a freshly generated, valid CNPJ.
  ///
  /// The first 8 characters (the root) are random. With [headOffice],
  /// positions 9–12 are `0001` (the conventional head-office branch
  /// identifier); otherwise they are a random branch number. Then come 2
  /// check digits. A [CnpjKind.alphanumeric] CNPJ always has at least one
  /// letter, so it cannot be mistaken for a numeric one.
  CnpjModel generate({
    CnpjKind kind = CnpjKind.numeric,
    bool headOffice = true,
  }) {
    final characters = switch (kind) {
      CnpjKind.numeric => _digits,
      CnpjKind.alphanumeric => _alphanumeric,
    };
    while (true) {
      final root = _randomText(8, characters);
      final branch = headOffice ? '0001' : _randomText(4, characters);
      final base = '$root$branch';
      if (!headOffice && (branch == '0000' || branch == '0001')) continue;
      if (kind == CnpjKind.alphanumeric && !base.contains(RegExp('[A-Z]'))) {
        continue;
      }
      return CnpjModel('$base${checkDigits(base)}');
    }
  }

  /// Returns [count] distinct CNPJs (see [generate]).
  List<CnpjModel> generateMany(
    int count, {
    CnpjKind kind = CnpjKind.numeric,
    bool headOffice = true,
  }) {
    final cnpjs = <CnpjModel>{};
    while (cnpjs.length < count) {
      cnpjs.add(generate(kind: kind, headOffice: headOffice));
    }
    return cnpjs.toList();
  }

  /// The two check digits of [base], the first 12 characters of a CNPJ.
  ///
  /// Each character counts as its ASCII code minus 48: digits keep their
  /// value and letters go from A = 17 to Z = 42. That is the rule the Receita
  /// Federal set for the alphanumeric CNPJ, and it leaves the numeric ones
  /// unchanged.
  static String checkDigits(String base) {
    final values = [for (final code in base.codeUnits) code - 48];
    final first = _checkDigit(values, _firstWeights);
    final second = _checkDigit([...values, first], _secondWeights);
    return '$first$second';
  }

  /// Computes a CNPJ check digit using the modulus 11 algorithm.
  static int _checkDigit(List<int> values, List<int> weights) {
    var sum = 0;
    for (var i = 0; i < weights.length; i++) {
      sum += values[i] * weights[i];
    }
    final remainder = sum % 11;
    return remainder < 2 ? 0 : 11 - remainder;
  }

  String _randomText(int length, String characters) => String.fromCharCodes([
    for (var i = 0; i < length; i++)
      characters.codeUnitAt(_random.nextInt(characters.length)),
  ]);
}
