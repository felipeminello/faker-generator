/// The 27 Brazilian federative units (states plus the Distrito Federal), with
/// the Receita Federal fiscal region each belongs to.
///
/// The region is the 9th digit of every CPF issued there, so it tells where a
/// CPF was registered (by region, not by state: region 1 covers five units).
enum Uf {
  ac('AC', 'Acre', 2),
  al('AL', 'Alagoas', 4),
  ap('AP', 'Amapá', 2),
  am('AM', 'Amazonas', 2),
  ba('BA', 'Bahia', 5),
  ce('CE', 'Ceará', 3),
  df('DF', 'Distrito Federal', 1),
  es('ES', 'Espírito Santo', 7),
  go('GO', 'Goiás', 1),
  ma('MA', 'Maranhão', 3),
  mt('MT', 'Mato Grosso', 1),
  ms('MS', 'Mato Grosso do Sul', 1),
  mg('MG', 'Minas Gerais', 6),
  pa('PA', 'Pará', 2),
  pb('PB', 'Paraíba', 4),
  pr('PR', 'Paraná', 9),
  pe('PE', 'Pernambuco', 4),
  pi('PI', 'Piauí', 3),
  rj('RJ', 'Rio de Janeiro', 7),
  rn('RN', 'Rio Grande do Norte', 4),
  rs('RS', 'Rio Grande do Sul', 0),
  ro('RO', 'Rondônia', 2),
  rr('RR', 'Roraima', 2),
  sc('SC', 'Santa Catarina', 9),
  sp('SP', 'São Paulo', 8),
  se('SE', 'Sergipe', 5),
  to('TO', 'Tocantins', 1);

  const Uf(this.code, this.fullName, this.fiscalRegion);

  /// Two-letter abbreviation ("SP").
  final String code;

  /// Full name ("São Paulo").
  final String fullName;

  /// Receita Federal fiscal region, 0 to 9.
  final int fiscalRegion;

  /// The units in fiscal [region], alphabetically by abbreviation.
  static List<Uf> ofRegion(int region) => [
    for (final uf in values)
      if (uf.fiscalRegion == region) uf,
  ]..sort((a, b) => a.code.compareTo(b.code));

  /// The units in fiscal [region] as text: "SP", or "PR e SC", or
  /// "DF, GO, MS, MT e TO".
  static String describeRegion(int region) {
    final codes = [for (final uf in ofRegion(region)) uf.code];
    if (codes.length == 1) return codes.single;
    return '${codes.sublist(0, codes.length - 1).join(', ')} e ${codes.last}';
  }
}
