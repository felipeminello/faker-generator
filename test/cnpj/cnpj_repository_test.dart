import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/cnpj/data/cnpj_repository.dart';

/// Validates a raw 14-digit CNPJ by recomputing its two check digits.
bool isValidCnpj(String digits) {
  if (digits.length != 14) return false;
  if (RegExp(r'^(\d)\1{13}$').hasMatch(digits)) return false;

  final numbers = digits.split('').map(int.parse).toList();
  const firstWeights = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  const secondWeights = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

  int check(List<int> weights) {
    var sum = 0;
    for (var i = 0; i < weights.length; i++) {
      sum += numbers[i] * weights[i];
    }
    final remainder = sum % 11;
    return remainder < 2 ? 0 : 11 - remainder;
  }

  return numbers[12] == check(firstWeights) &&
      numbers[13] == check(secondWeights);
}

void main() {
  group('CnpjRepository', () {
    test('generates 14 numeric digits', () {
      final cnpj = CnpjRepository().generate();
      expect(cnpj.digits, matches(RegExp(r'^\d{14}$')));
    });

    test('formats as XX.XXX.XXX/XXXX-XX', () {
      final cnpj = CnpjRepository().generate();
      expect(
        cnpj.formatted,
        matches(RegExp(r'^\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}$')),
      );
    });

    test('uses the 0001 head-office branch', () {
      final cnpj = CnpjRepository().generate();
      expect(cnpj.digits.substring(8, 12), '0001');
    });

    test('always produces valid check digits', () {
      final repo = CnpjRepository();
      for (var i = 0; i < 1000; i++) {
        expect(isValidCnpj(repo.generate().digits), isTrue);
      }
    });

    test('is deterministic with a seeded Random', () {
      final a = CnpjRepository(random: Random(99)).generate();
      final b = CnpjRepository(random: Random(99)).generate();
      expect(a, b);
    });
  });
}
