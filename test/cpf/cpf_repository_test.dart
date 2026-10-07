import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/cpf/data/cpf_model.dart';
import 'package:fake_generator/cpf/data/cpf_repository.dart';
import 'package:fake_generator/cpf/data/uf.dart';

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
      expect(cpf.formatted, matches(RegExp(r'^\d{3}\.\d{3}\.\d{3}-\d{2}$')));
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

    test('puts the fiscal region of the chosen unit in the 9th digit', () {
      final repo = CpfRepository();
      for (final uf in Uf.values) {
        final cpf = repo.generate(uf: uf);
        expect(cpf.fiscalRegion, uf.fiscalRegion, reason: uf.code);
        expect(isValidCpf(cpf.digits), isTrue);
      }
    });

    test('generateMany returns that many distinct, valid CPFs', () {
      final cpfs = CpfRepository().generateMany(
        CpfRepository.maxCount,
        uf: Uf.sp,
      );

      expect(cpfs, hasLength(CpfRepository.maxCount));
      expect(cpfs.toSet(), hasLength(CpfRepository.maxCount));
      for (final cpf in cpfs) {
        expect(isValidCpf(cpf.digits), isTrue);
        expect(cpf.fiscalRegion, 8);
      }
    });

    test('checkDigits matches known CPFs', () {
      expect(CpfRepository.checkDigits('123456789'), '09');
      expect(CpfRepository.checkDigits('111444777'), '35');
      expect(CpfRepository.checkDigits('012345678'), '90');
    });
  });

  group('CpfModel', () {
    test('describes its fiscal region', () {
      expect(const CpfModel('12345678909').regionDescription, 'PR e SC');
      expect(const CpfModel('11144477735').regionDescription, 'ES e RJ');
      expect(
        const CpfModel('00000001191').regionDescription,
        'DF, GO, MS, MT e TO',
      );
    });
  });
}
