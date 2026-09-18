/// Immutable representation of a generated CNPJ.
class CnpjModel {
  const CnpjModel(this.digits);

  /// The 14 raw digits of the CNPJ (no punctuation).
  final String digits;

  /// The CNPJ formatted as `XX.XXX.XXX/XXXX-XX`.
  String get formatted =>
      '${digits.substring(0, 2)}.${digits.substring(2, 5)}'
      '.${digits.substring(5, 8)}/${digits.substring(8, 12)}'
      '-${digits.substring(12, 14)}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CnpjModel && other.digits == digits);

  @override
  int get hashCode => digits.hashCode;

  @override
  String toString() => 'CnpjModel($formatted)';
}
