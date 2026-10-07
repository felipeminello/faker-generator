import 'cnpj_kind.dart';

/// Immutable representation of a generated CNPJ.
class CnpjModel {
  const CnpjModel(this.raw);

  /// The 14 characters of the CNPJ, without punctuation: 12 digits or
  /// uppercase letters, then 2 check digits.
  final String raw;

  /// The CNPJ formatted as `XX.XXX.XXX/XXXX-XX`.
  String get formatted =>
      '${raw.substring(0, 2)}.${raw.substring(2, 5)}'
      '.${raw.substring(5, 8)}/${raw.substring(8, 12)}'
      '-${raw.substring(12, 14)}';

  /// The first 8 characters, shared by the head office and its branches.
  String get root => raw.substring(0, 8);

  /// Characters 9–12: `0001` for the head office, another order number for
  /// each branch.
  String get branch => raw.substring(8, 12);

  /// Whether this is the company's head office (branch `0001`).
  bool get isHeadOffice => branch == '0001';

  CnpjKind get kind =>
      raw.contains(RegExp('[A-Z]')) ? CnpjKind.alphanumeric : CnpjKind.numeric;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CnpjModel && other.raw == raw);

  @override
  int get hashCode => raw.hashCode;

  @override
  String toString() => 'CnpjModel($formatted)';
}
