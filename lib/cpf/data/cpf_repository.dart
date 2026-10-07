import 'dart:math';

import 'cpf_model.dart';
import 'uf.dart';

/// Generates valid Brazilian CPF numbers (with correct check digits).
class CpfRepository {
  CpfRepository({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  /// Largest batch [generateMany] makes.
  static const maxCount = 1000;

  /// Returns a freshly generated, valid CPF.
  ///
  /// With [uf], its 9th digit is that unit's fiscal region, as on a CPF
  /// registered there. Numbers made of a single repeated digit
  /// (111.111.111-11) pass the check digits but are never issued, so they are
  /// skipped.
  CpfModel generate({Uf? uf}) {
    while (true) {
      final digits = List<int>.generate(9, (_) => _random.nextInt(10));
      if (uf != null) digits[8] = uf.fiscalRegion;
      final base = digits.join();
      if (_isRepeated(base)) continue;
      return CpfModel('$base${checkDigits(base)}');
    }
  }

  /// Returns [count] distinct CPFs (see [generate]).
  List<CpfModel> generateMany(int count, {Uf? uf}) {
    final cpfs = <CpfModel>{};
    while (cpfs.length < count) {
      cpfs.add(generate(uf: uf));
    }
    return cpfs.toList();
  }

  /// The two check digits of [base], the first 9 digits of a CPF.
  static String checkDigits(String base) {
    final digits = base.split('').map(int.parse).toList();
    final first = _checkDigit(digits, startWeight: 10);
    final second = _checkDigit([...digits, first], startWeight: 11);
    return '$first$second';
  }

  /// Computes a CPF check digit using the modulus 11 algorithm.
  ///
  /// Each digit is multiplied by a decreasing weight starting at [startWeight];
  /// the check digit is `11 - (sum % 11)`, or `0` when that result is 10 or 11.
  static int _checkDigit(List<int> digits, {required int startWeight}) {
    var sum = 0;
    var weight = startWeight;
    for (final digit in digits) {
      sum += digit * weight;
      weight--;
    }
    final remainder = sum % 11;
    return remainder < 2 ? 0 : 11 - remainder;
  }

  static bool _isRepeated(String base) => RegExp(r'^(.)\1*$').hasMatch(base);
}
