/// The two CNPJ formats.
enum CnpjKind {
  /// The classic one: 14 digits.
  numeric('Numérico'),

  /// The one the Receita Federal issues since July 2026 (IN RFB 2.229/2024):
  /// the first 12 characters may be uppercase letters too; the 2 check digits
  /// are still numbers. Existing CNPJs keep their numbers.
  alphanumeric('Alfanumérico');

  const CnpjKind(this.label);

  final String label;
}
