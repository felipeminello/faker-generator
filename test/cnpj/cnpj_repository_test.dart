import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/cnpj/data/cnpj_kind.dart';
import 'package:fake_generator/cnpj/data/cnpj_model.dart';
import 'package:fake_generator/cnpj/data/cnpj_repository.dart';

/// Validates a raw 14-character CNPJ by recomputing its two check digits,
/// following the Receita Federal rule for the alphanumeric format: each
/// character counts as its ASCII code minus 48.
bool isValidCnpj(String raw) {
  if (!RegExp(r'^[0-9A-Z]{12}\d{2}$').hasMatch(raw)) return false;
  if (RegExp(r'^(.)\1{13}$').hasMatch(raw)) return false;

  final values = raw.codeUnits.map((code) => code - 48).toList();
  const firstWeights = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  const secondWeights = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

  int check(List<int> weights) {
    var sum = 0;
    for (var i = 0; i < weights.length; i++) {
      sum += values[i] * weights[i];
    }
    final remainder = sum % 11;
    return remainder < 2 ? 0 : 11 - remainder;
  }

  return values[12] == check(firstWeights) &&
      values[13] == check(secondWeights);
}

void main() {
  group('CnpjRepository', () {
    test('generates 14 numeric digits by default', () {
      final cnpj = CnpjRepository().generate();
      expect(cnpj.raw, matches(RegExp(r'^\d{14}$')));
      expect(cnpj.kind, CnpjKind.numeric);
    });

    test('formats as XX.XXX.XXX/XXXX-XX', () {
      final cnpj = CnpjRepository().generate();
      expect(
        cnpj.formatted,
        matches(RegExp(r'^\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}$')),
      );
    });

    test('uses the 0001 head-office branch by default', () {
      final cnpj = CnpjRepository().generate();
      expect(cnpj.branch, '0001');
      expect(cnpj.isHeadOffice, isTrue);
    });

    test('always produces valid check digits', () {
      final repo = CnpjRepository();
      for (var i = 0; i < 1000; i++) {
        expect(isValidCnpj(repo.generate().raw), isTrue);
      }
    });

    test('is deterministic with a seeded Random', () {
      final a = CnpjRepository(random: Random(99)).generate();
      final b = CnpjRepository(random: Random(99)).generate();
      expect(a, b);
    });

    test('alphanumeric CNPJs have letters and numeric check digits', () {
      final repo = CnpjRepository();
      for (var i = 0; i < 1000; i++) {
        final cnpj = repo.generate(kind: CnpjKind.alphanumeric);
        expect(cnpj.raw, matches(RegExp(r'^[0-9A-Z]{12}\d{2}$')));
        expect(cnpj.root, matches(RegExp('[A-Z]')));
        expect(cnpj.kind, CnpjKind.alphanumeric);
        expect(isValidCnpj(cnpj.raw), isTrue, reason: cnpj.formatted);
      }
    });

    test('branches never use 0000 or the head-office 0001', () {
      final repo = CnpjRepository();
      for (final kind in CnpjKind.values) {
        for (var i = 0; i < 500; i++) {
          final cnpj = repo.generate(kind: kind, headOffice: false);
          expect(cnpj.branch, isNot(anyOf('0000', '0001')));
          expect(cnpj.isHeadOffice, isFalse);
          expect(isValidCnpj(cnpj.raw), isTrue);
        }
      }
    });

    test('generateMany returns that many distinct CNPJs', () {
      final cnpjs = CnpjRepository().generateMany(
        CnpjRepository.maxCount,
        kind: CnpjKind.alphanumeric,
        headOffice: false,
      );

      expect(cnpjs, hasLength(CnpjRepository.maxCount));
      expect(cnpjs.toSet(), hasLength(CnpjRepository.maxCount));
      expect(cnpjs.every((cnpj) => isValidCnpj(cnpj.raw)), isTrue);
    });

    test('checkDigits matches the numeric CNPJs it always did', () {
      expect(CnpjRepository.checkDigits('112223330001'), '81');
      expect(CnpjRepository.checkDigits('112223330002'), '62');
    });

    test('checkDigits matches the Receita Federal alphanumeric example', () {
      // 12.ABC.345/01DE-35, the example in the Receita Federal's guide to
      // the alphanumeric CNPJ.
      expect(CnpjRepository.checkDigits('12ABC34501DE'), '35');
      expect(CnpjRepository.checkDigits('12ABC3450001'), '88');
    });
  });

  group('CnpjModel', () {
    test('splits into root, branch and check digits', () {
      const cnpj = CnpjModel('12ABC34501DE35');

      expect(cnpj.formatted, '12.ABC.345/01DE-35');
      expect(cnpj.root, '12ABC345');
      expect(cnpj.branch, '01DE');
      expect(cnpj.isHeadOffice, isFalse);
      expect(cnpj.kind, CnpjKind.alphanumeric);
    });
  });
}
