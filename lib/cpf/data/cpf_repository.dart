import 'dart:math';

import 'cpf_model.dart';

/// Generates valid Brazilian CPF numbers (with correct check digits).
class CpfRepository {
  CpfRepository({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  /// Returns a freshly generated, valid CPF.
  CpfModel generate() {
    final digits = List<int>.generate(9, (_) => _random.nextInt(10));

    digits.add(_checkDigit(digits, startWeight: 10));
    digits.add(_checkDigit(digits, startWeight: 11));

    return CpfModel(digits.join());
  }

  /// Computes a CPF check digit using the modulus 11 algorithm.
  ///
  /// Each digit is multiplied by a decreasing weight starting at [startWeight];
  /// the check digit is `11 - (sum % 11)`, or `0` when that result is 10 or 11.
  int _checkDigit(List<int> digits, {required int startWeight}) {
    var sum = 0;
    var weight = startWeight;
    for (final digit in digits) {
      sum += digit * weight;
      weight--;
    }
    final remainder = sum % 11;
    return remainder < 2 ? 0 : 11 - remainder;
  }
}
