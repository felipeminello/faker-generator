part of 'lorem_bloc.dart';

/// State of the Lorem Ipsum feature: the generation options plus the text
/// currently on screen.
///
/// Unlike the other generators this feature is configurable, so a single state
/// class carries the options instead of a sealed empty/generated pair; the
/// empty state is [lorem] being `null`.
class LoremState {
  const LoremState({
    this.unit = LoremUnit.paragraphs,
    this.count = 3,
    this.startWithLorem = true,
    this.lorem,
  });

  /// Unit the amount refers to.
  final LoremUnit unit;

  /// How many [unit]s to generate.
  final int count;

  /// Whether the text opens with "Lorem ipsum dolor sit amet...".
  final bool startWithLorem;

  /// The generated text, or `null` before the first generation / after
  /// clearing.
  final LoremModel? lorem;

  /// Whether there is a text to copy or clear.
  bool get hasText => lorem != null;

  LoremState copyWith({
    LoremUnit? unit,
    int? count,
    bool? startWithLorem,
    LoremModel? lorem,
    bool clearLorem = false,
  }) {
    return LoremState(
      unit: unit ?? this.unit,
      count: count ?? this.count,
      startWithLorem: startWithLorem ?? this.startWithLorem,
      lorem: clearLorem ? null : (lorem ?? this.lorem),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoremState &&
          other.unit == unit &&
          other.count == count &&
          other.startWithLorem == startWithLorem &&
          other.lorem == lorem);

  @override
  int get hashCode => Object.hash(unit, count, startWithLorem, lorem);

  @override
  String toString() =>
      'LoremState($count ${unit.hint}, startWithLorem: $startWithLorem, '
      'lorem: $lorem)';
}
