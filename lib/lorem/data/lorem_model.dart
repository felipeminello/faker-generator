import 'lorem_unit.dart';

/// Immutable representation of a generated placeholder text.
class LoremModel {
  const LoremModel({
    required this.text,
    required this.unit,
    required this.count,
  });

  /// The generated text. Paragraphs are separated by a blank line and list
  /// items by a single line break.
  final String text;

  /// The unit that was requested.
  final LoremUnit unit;

  /// The amount that was requested (already clamped to [LoremUnit]'s range).
  final int count;

  /// Number of characters in [text].
  int get characterCount => text.length;

  /// Number of whitespace-separated tokens that contain at least one letter,
  /// so list bullets are not counted as words.
  int get wordCount => text
      .split(RegExp(r'\s+'))
      .where((token) => RegExp('[A-Za-z]').hasMatch(token))
      .length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoremModel &&
          other.text == text &&
          other.unit == unit &&
          other.count == count);

  @override
  int get hashCode => Object.hash(text, unit, count);

  @override
  String toString() => 'LoremModel($count ${unit.hint}, $characterCount chars)';
}
