import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/cnpj/data/cnpj_kind.dart';
import 'package:fake_generator/cnpj/data/cnpj_repository.dart';
import 'package:fake_generator/cpf/data/cpf_repository.dart';
import 'package:fake_generator/validator/data/document_validation.dart';
import 'package:fake_generator/validator/data/validator_repository.dart';

void main() {
  const repository = ValidatorRepository();

  group('ValidatorRepository.validate', () {
    test('accepts a valid CPF and tells its fiscal region', () {
      final result = repository.validate('123.456.789-09');

      expect(result.isValid, isTrue);
      expect(result.type, DocumentType.cpf);
      expect(result.title, 'CPF válido');
      expect(result.formatted, '123.456.789-09');
      expect(result.details, ['Região fiscal 9: PR e SC']);
    });

    test('ignores punctuation and spaces', () {
      for (final input in ['12345678909', '123 456 789 09', '123.456.789/09']) {
        expect(repository.validate(input).isValid, isTrue, reason: input);
      }
    });

    test('accepts a numeric CNPJ and tells head office from branch', () {
      final headOffice = repository.validate('11.222.333/0001-81');
      final branch = repository.validate('11222333000262');

      expect(headOffice.isValid, isTrue);
      expect(headOffice.type, DocumentType.cnpj);
      expect(headOffice.details, ['Numérico', 'Matriz', 'Raiz 11.222.333']);
      expect(branch.isValid, isTrue);
      expect(branch.formatted, '11.222.333/0002-62');
      expect(branch.details, ['Numérico', 'Filial 0002', 'Raiz 11.222.333']);
    });

    test('accepts an alphanumeric CNPJ, in any case', () {
      for (final input in ['12.ABC.345/01DE-35', '12abc34501de35']) {
        final result = repository.validate(input);

        expect(result.isValid, isTrue, reason: input);
        expect(result.formatted, '12.ABC.345/01DE-35');
        expect(result.details, [
          'Alfanumérico',
          'Filial 01DE',
          'Raiz 12.ABC.345',
        ]);
      }
      expect(repository.validate('12.ABC.345/0001-88').isValid, isTrue);
    });

    test('accepts everything the generators make', () {
      final cpfs = CpfRepository().generateMany(200);
      final cnpjs = [
        for (final kind in CnpjKind.values)
          ...CnpjRepository().generateMany(100, kind: kind, headOffice: false),
      ];

      for (final value in [
        for (final cpf in cpfs) ...[cpf.formatted, cpf.digits],
        for (final cnpj in cnpjs) ...[cnpj.formatted, cnpj.raw],
      ]) {
        expect(repository.validate(value).isValid, isTrue, reason: value);
      }
    });

    test('points out wrong check digits and the right ones', () {
      final cpf = repository.validate('123.456.789-00');
      final cnpj = repository.validate('12.ABC.345/01DE-53');

      expect(cpf.problem, DocumentProblem.checkDigits);
      expect(cpf.title, 'CPF inválido');
      expect(
        cpf.explanation,
        'Dígitos verificadores errados: deveriam ser 09, não 00.',
      );
      expect(cpf.suggestion, '123.456.789-09');
      expect(cnpj.problem, DocumentProblem.checkDigits);
      expect(cnpj.suggestion, '12.ABC.345/01DE-35');
    });

    test('rejects a repeated digit even though the check digits work', () {
      final result = repository.validate('111.111.111-11');

      expect(result.problem, DocumentProblem.repeated);
      expect(result.type, DocumentType.cpf);
      expect(result.suggestion, isNull);
    });

    test('suggests the leading zeros a spreadsheet dropped', () {
      final cpf = repository.validate('1234567890');
      final cnpj = repository.validate('1222333000128');

      expect(cpf.problem, DocumentProblem.length);
      expect(cpf.title, 'Nem CPF nem CNPJ');
      expect(cpf.suggestion, '012.345.678-90');
      expect(cpf.explanation, contains('zeros à esquerda'));
      expect(cnpj.suggestion, '01.222.333/0001-28');
    });

    test('explains a length that fits neither document', () {
      final result = repository.validate('123');

      expect(result.problem, DocumentProblem.length);
      expect(result.type, isNull);
      expect(
        result.explanation,
        'Tem 3 caracteres: um CPF tem 11 e um CNPJ, 14.',
      );
      expect(result.suggestion, isNull);
    });

    test('rejects characters neither document has', () {
      final letterInCpf = repository.validate('123.456.789-0A');
      final letterInCheckDigits = repository.validate('12.ABC.345/01DE-3X');
      final symbol = repository.validate('123.456.789-09#');

      expect(letterInCpf.problem, DocumentProblem.characters);
      expect(letterInCpf.type, DocumentType.cpf);
      expect(letterInCheckDigits.problem, DocumentProblem.characters);
      expect(letterInCheckDigits.type, DocumentType.cnpj);
      expect(symbol.problem, DocumentProblem.characters);
      expect(symbol.explanation, '"#" não faz parte de CPF nem de CNPJ.');
    });
  });

  group('ValidatorRepository.validateAll', () {
    test('checks one value per line, skipping blank ones', () {
      final results = repository.validateAll(
        '123.456.789-09\n\n  11.222.333/0001-81  \n123',
      );

      expect(
        [for (final result in results) result.input],
        ['123.456.789-09', '11.222.333/0001-81', '123'],
      );
      expect(
        [for (final result in results) result.isValid],
        [true, true, false],
      );
    });

    test('reads a CSV column or a JSON array as pasted', () {
      const csv = 'cpf\n123.456.789-09\n"111.444.777-35"\r\n';
      const json = '[\n  "11.222.333/0001-81",\n  "12.ABC.345/01DE-35"\n]';

      expect(repository.validateAll(csv).map((result) => result.formatted), [
        '123.456.789-09',
        '111.444.777-35',
      ]);
      expect(repository.validateAll(json).map((result) => result.formatted), [
        '11.222.333/0001-81',
        '12.ABC.345/01DE-35',
      ]);
    });

    test('the example shows each verdict', () {
      final results = repository.validateAll(ValidatorRepository.example);

      expect(
        [for (final result in results) result.problem],
        [
          null,
          DocumentProblem.checkDigits,
          DocumentProblem.length,
          DocumentProblem.repeated,
          null,
          null,
        ],
      );
      expect(results[2].suggestion, isNotNull);
    });
  });
}
