import 'dart:math';

import 'cnpj_model.dart';

/// Generates valid Brazilian CNPJ numbers (with correct check digits).
class CnpjRepository {
  CnpjRepository({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  // Modulus 11 weights applied right-to-left across the base digits.
  static const List<int> _firstWeights = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  static const List<int> _secondWeights = [
    6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2, //
  ];

  /// Returns a freshly generated, valid CNPJ.
  ///
  /// The first 8 digits are random and positions 9–12 are `0001` (the
  /// conventional head-office branch identifier), followed by 2 check digits.
  CnpjModel generate() {
    final digits = <int>[
      ...List<int>.generate(8, (_) => _random.nextInt(10)),
      0, 0, 0, 1, //
    ];

    digits.add(_checkDigit(digits, _firstWeights));
    digits.add(_checkDigit(digits, _secondWeights));

    return CnpjModel(digits.join());
  }

  /// Computes a CNPJ check digit using the modulus 11 algorithm.
  int _checkDigit(List<int> digits, List<int> weights) {
    var sum = 0;
    for (var i = 0; i < weights.length; i++) {
      sum += digits[i] * weights[i];
    }
    final remainder = sum % 11;
    return remainder < 2 ? 0 : 11 - remainder;
  }
}
