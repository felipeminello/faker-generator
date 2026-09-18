/// The unit the user picks when asking for placeholder text.
///
/// Each unit carries the range accepted by the amount field and the amount
/// used when the unit is selected, so the UI and the Bloc share one source of
/// truth for the limits.
enum LoremUnit {
  paragraphs(
    label: 'Parágrafos',
    hint: 'parágrafos',
    min: 1,
    max: 50,
    defaultCount: 3,
  ),
  words(
    label: 'Palavras',
    hint: 'palavras',
    min: 1,
    max: 1000,
    defaultCount: 50,
  ),
  letters(
    label: 'Letras',
    hint: 'letras',
    min: 1,
    max: 5000,
    defaultCount: 250,
  ),
  lists(
    label: 'Listas',
    hint: 'itens de lista',
    min: 1,
    max: 50,
    defaultCount: 5,
  );

  const LoremUnit({
    required this.label,
    required this.hint,
    required this.min,
    required this.max,
    required this.defaultCount,
  });

  /// Short label shown on the unit selector.
  final String label;

  /// Plural noun used in helper texts ("3 parágrafos").
  final String hint;

  /// Smallest amount accepted for this unit.
  final int min;

  /// Largest amount accepted for this unit.
  final int max;

  /// Amount applied when the user switches to this unit.
  final int defaultCount;

  /// Clamps [count] into the `[min, max]` range accepted by this unit.
  int clampCount(int count) => count.clamp(min, max);
}
