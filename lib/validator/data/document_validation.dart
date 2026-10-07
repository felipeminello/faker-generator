import 'package:flutter/foundation.dart';

/// Which document a typed value was taken for, by its length.
enum DocumentType {
  cpf('CPF'),
  cnpj('CNPJ');

  const DocumentType(this.label);

  final String label;
}

/// Why a value is not a valid CPF or CNPJ.
enum DocumentProblem {
  /// Fits neither length: 11 for a CPF, 14 for a CNPJ.
  length,

  /// Has a character the document cannot have.
  characters,

  /// A single character repeated (111.111.111-11): the check digits work out,
  /// but such numbers are never issued and systems reject them.
  repeated,

  /// The check digits do not match the rest.
  checkDigits,
}

/// The verdict on one typed value: valid, or what is wrong with it.
class DocumentValidation {
  const DocumentValidation({
    required this.input,
    this.type,
    this.problem,
    this.explanation,
    this.formatted,
    this.suggestion,
    this.details = const [],
  });

  /// The value as typed, trimmed.
  final String input;

  /// What the value was taken for; `null` when its length fits neither.
  final DocumentType? type;

  /// What is wrong, or `null` when the value is valid.
  final DocumentProblem? problem;

  /// The [problem], in Portuguese ("Dígitos verificadores errados: ...").
  final String? explanation;

  /// The value with the document's punctuation, when it has the right length
  /// and characters.
  final String? formatted;

  /// The valid document the value most likely meant, formatted: the right
  /// check digits, or the leading zeros a spreadsheet dropped.
  final String? suggestion;

  /// What a valid document says about itself ("Região fiscal 8: SP",
  /// "Matriz"...). Empty when invalid.
  final List<String> details;

  bool get isValid => problem == null;

  /// One-line verdict: "CPF válido", "CNPJ inválido", "Nem CPF nem CNPJ".
  String get title => switch ((type, isValid)) {
    (null, _) => 'Nem CPF nem CNPJ',
    (final type?, true) => '${type.label} válido',
    (final type?, false) => '${type.label} inválido',
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentValidation &&
          other.input == input &&
          other.type == type &&
          other.problem == problem &&
          other.explanation == explanation &&
          other.formatted == formatted &&
          other.suggestion == suggestion &&
          listEquals(other.details, details));

  @override
  int get hashCode => Object.hash(
    input,
    type,
    problem,
    explanation,
    formatted,
    suggestion,
    Object.hashAll(details),
  );

  @override
  String toString() =>
      'DocumentValidation("$input", $title, ${problem?.name}, '
      'suggestion: $suggestion, details: $details)';
}
