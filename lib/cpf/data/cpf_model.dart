/// Immutable representation of a generated CPF.
class CpfModel {
  const CpfModel(this.digits);

  /// The 11 raw digits of the CPF (no punctuation).
  final String digits;

  /// The CPF formatted as `XXX.XXX.XXX-XX`.
  String get formatted =>
      '${digits.substring(0, 3)}.${digits.substring(3, 6)}'
      '.${digits.substring(6, 9)}-${digits.substring(9, 11)}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CpfModel && other.digits == digits);

  @override
  int get hashCode => digits.hashCode;

  @override
  String toString() => 'CpfModel($formatted)';
}
