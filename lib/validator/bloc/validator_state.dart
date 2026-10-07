part of 'validator_bloc.dart';

/// State of the validator: the text as typed and the verdict on each value
/// in it.
///
/// The empty state is [text] being empty.
class ValidatorState {
  const ValidatorState({this.text = '', this.results = const []});

  /// The text as typed: one value per line.
  final String text;

  /// One verdict per line that holds a value, in order.
  final List<DocumentValidation> results;

  /// Whether there is a text to clear.
  bool get hasText => text.isNotEmpty;

  int get validCount => results.where((result) => result.isValid).length;

  int get invalidCount => results.length - validCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ValidatorState &&
          other.text == text &&
          listEquals(other.results, results));

  @override
  int get hashCode => Object.hash(text, Object.hashAll(results));

  @override
  String toString() => 'ValidatorState("$text", results: $results)';
}
