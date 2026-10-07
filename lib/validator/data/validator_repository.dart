import 'dart:convert';

import '../../cnpj/data/cnpj_model.dart';
import '../../cnpj/data/cnpj_repository.dart';
import '../../cpf/data/cpf_model.dart';
import '../../cpf/data/cpf_repository.dart';
import 'document_validation.dart';

/// Checks CPFs and CNPJs (numeric or alphanumeric), telling them apart by
/// length: 11 characters for a CPF, 14 for a CNPJ.
class ValidatorRepository {
  const ValidatorRepository();

  /// What "Ver exemplo" fills in: a valid CPF, the same CPF with wrong check
  /// digits, a CPF whose leading zero a spreadsheet dropped, a repeated one,
  /// and a valid CNPJ in each format.
  static const example =
      '123.456.789-09\n'
      '123.456.789-00\n'
      '1234567890\n'
      '111.111.111-11\n'
      '11.222.333/0001-81\n'
      '12.ABC.345/01DE-35';

  static final _punctuation = RegExp(r'[.\-/\s]');

  /// Quotes, separators and brackets around a value pasted from a CSV or a
  /// JSON array.
  static final _wrapping = RegExp(r'''^[\s"',;\[\]]+|[\s"',;\[\]]+$''');

  /// Validates each line of [text] that holds a value.
  ///
  /// Lines pasted from a CSV or a JSON array work too: quotes, commas and
  /// brackets around the value are ignored, and so are `cpf`/`cnpj` headers
  /// and the lines that hold only brackets.
  List<DocumentValidation> validateAll(String text) => [
    for (final line in const LineSplitter().convert(text))
      if (line.replaceAll(_wrapping, '') case final value
          when value.isNotEmpty && !_isHeader(value))
        validate(value),
  ];

  /// Validates a single value, with or without punctuation. Letters may be
  /// lowercase: the alphanumeric CNPJ uses uppercase ones, so they are
  /// uppercased first.
  DocumentValidation validate(String input) {
    final compact = input.replaceAll(_punctuation, '').toUpperCase();
    final type = switch (compact.length) {
      11 => DocumentType.cpf,
      14 => DocumentType.cnpj,
      _ => null,
    };

    final stray = RegExp('[^0-9A-Z]').firstMatch(compact)?[0];
    if (stray != null) {
      return DocumentValidation(
        input: input,
        type: type,
        problem: DocumentProblem.characters,
        explanation: type == null
            ? '"$stray" não faz parte de CPF nem de CNPJ.'
            : '"$stray" não faz parte de um ${type.label}.',
      );
    }

    return switch (type) {
      DocumentType.cpf => _validateCpf(input, compact),
      DocumentType.cnpj => _validateCnpj(input, compact),
      null => _wrongLength(input, compact),
    };
  }

  DocumentValidation _validateCpf(String input, String digits) {
    if (digits.contains(RegExp('[A-Z]'))) {
      return DocumentValidation(
        input: input,
        type: DocumentType.cpf,
        problem: DocumentProblem.characters,
        explanation:
            'Um CPF só tem números. Letras só aparecem no CNPJ '
            'alfanumérico, de 14 caracteres.',
      );
    }

    final cpf = CpfModel(digits);
    if (_isRepeated(digits)) {
      return _repeated(input, DocumentType.cpf, cpf.formatted);
    }

    final base = digits.substring(0, 9);
    final expected = CpfRepository.checkDigits(base);
    if (digits.substring(9) != expected) {
      return _wrongCheckDigits(
        input,
        DocumentType.cpf,
        formatted: cpf.formatted,
        expected: expected,
        actual: digits.substring(9),
        suggestion: CpfModel('$base$expected').formatted,
      );
    }

    return DocumentValidation(
      input: input,
      type: DocumentType.cpf,
      formatted: cpf.formatted,
      details: ['Região fiscal ${cpf.fiscalRegion}: ${cpf.regionDescription}'],
    );
  }

  DocumentValidation _validateCnpj(String input, String raw) {
    if (raw.substring(12).contains(RegExp('[A-Z]'))) {
      return DocumentValidation(
        input: input,
        type: DocumentType.cnpj,
        problem: DocumentProblem.characters,
        explanation:
            'Os 2 últimos caracteres de um CNPJ, os dígitos verificadores, '
            'são sempre números.',
      );
    }

    final cnpj = CnpjModel(raw);
    if (_isRepeated(raw)) {
      return _repeated(input, DocumentType.cnpj, cnpj.formatted);
    }

    final base = raw.substring(0, 12);
    final expected = CnpjRepository.checkDigits(base);
    if (raw.substring(12) != expected) {
      return _wrongCheckDigits(
        input,
        DocumentType.cnpj,
        formatted: cnpj.formatted,
        expected: expected,
        actual: raw.substring(12),
        suggestion: CnpjModel('$base$expected').formatted,
      );
    }

    return DocumentValidation(
      input: input,
      type: DocumentType.cnpj,
      formatted: cnpj.formatted,
      details: [
        cnpj.kind.label,
        cnpj.isHeadOffice ? 'Matriz' : 'Filial ${cnpj.branch}',
        'Raiz ${cnpj.formatted.substring(0, 10)}',
      ],
    );
  }

  /// A value that fits neither length. When it is all digits and up to two
  /// short, the leading zeros a spreadsheet drops may be what is missing.
  DocumentValidation _wrongLength(String input, String compact) {
    final length = compact.length;
    final digitsOnly = RegExp(r'^\d+$').hasMatch(compact);
    final suggestion = !digitsOnly
        ? null
        : switch (length) {
            9 || 10 => _validCpf(compact.padLeft(11, '0'))?.formatted,
            12 || 13 => _validCnpj(compact.padLeft(14, '0'))?.formatted,
            _ => null,
          };

    return DocumentValidation(
      input: input,
      problem: DocumentProblem.length,
      explanation: [
        'Tem $length ${length == 1 ? 'caractere' : 'caracteres'}: um CPF '
            'tem 11 e um CNPJ, 14.',
        if (suggestion != null)
          'Planilhas costumam apagar os zeros à esquerda.',
      ].join(' '),
      suggestion: suggestion,
    );
  }

  DocumentValidation _repeated(
    String input,
    DocumentType type,
    String formatted,
  ) => DocumentValidation(
    input: input,
    type: type,
    problem: DocumentProblem.repeated,
    explanation:
        'Todos os caracteres iguais: a conta dos dígitos fecha, mas esse '
        'número nunca é emitido e os sistemas o recusam.',
    formatted: formatted,
  );

  DocumentValidation _wrongCheckDigits(
    String input,
    DocumentType type, {
    required String formatted,
    required String expected,
    required String actual,
    required String suggestion,
  }) => DocumentValidation(
    input: input,
    type: type,
    problem: DocumentProblem.checkDigits,
    explanation:
        'Dígitos verificadores errados: deveriam ser $expected, não $actual.',
    formatted: formatted,
    suggestion: suggestion,
  );

  CpfModel? _validCpf(String digits) {
    if (_isRepeated(digits)) return null;
    final base = digits.substring(0, 9);
    return digits.substring(9) == CpfRepository.checkDigits(base)
        ? CpfModel(digits)
        : null;
  }

  CnpjModel? _validCnpj(String digits) {
    if (_isRepeated(digits)) return null;
    final base = digits.substring(0, 12);
    return digits.substring(12) == CnpjRepository.checkDigits(base)
        ? CnpjModel(digits)
        : null;
  }

  static bool _isRepeated(String value) => RegExp(r'^(.)\1*$').hasMatch(value);

  static bool _isHeader(String value) =>
      const {'cpf', 'cnpj'}.contains(value.toLowerCase());
}
