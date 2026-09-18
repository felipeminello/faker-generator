import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:uuid_generator/cpf/data/cpf_repository.dart';

/// Validates a raw 11-digit CPF by recomputing its two check digits.
bool isValidCpf(String digits) {
  if (digits.length != 11) return false;
  if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return false;

  final numbers = digits.split('').map(int.parse).toList();

  int check(int count) {
    var sum = 0;
    for (var i = 0; i < count; i++) {
      sum += numbers[i] * (count + 1 - i);
    }
    final remainder = sum % 11;
    return remainder < 2 ? 0 : 11 - remainder;
  }

  return numbers[9] == check(9) && numbers[10] == check(10);
}

void main() {
  group('CpfRepository', () {
    test('generates 11 numeric digits', () {
      final cpf = CpfRepository().generate();
      expect(cpf.digits, matches(RegExp(r'^\d{11}$')));
    });

    test('formats as XXX.XXX.XXX-XX', () {
      final cpf = CpfRepository().generate();
      expect(
        cpf.formatted,
        matches(RegExp(r'^\d{3}\.\d{3}\.\d{3}-\d{2}$')),
      );
    });

    test('always produces valid check digits', () {
      final repo = CpfRepository();
      for (var i = 0; i < 1000; i++) {
        expect(isValidCpf(repo.generate().digits), isTrue);
      }
    });

    test('is deterministic with a seeded Random', () {
      final a = CpfRepository(random: Random(7)).generate();
      final b = CpfRepository(random: Random(7)).generate();
      expect(a, b);
    });
  });
}
