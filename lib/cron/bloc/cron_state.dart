part of 'cron_bloc.dart';

/// State of the cron editor: the expression being edited and what it means.
///
/// Like `LoremState`, a single class carries everything. The empty state is
/// [expression] being blank; otherwise exactly one of [cron] (valid) and
/// [error] (invalid) is set.
class CronState {
  const CronState({
    this.expression = '',
    this.cron,
    this.error,
    this.activeField,
    this.fieldSpans = const [],
  });

  /// The expression as typed, spaces included, so the text field and the
  /// state never disagree while the user is typing.
  final String expression;

  /// The explained expression, when it is valid.
  final CronModel? cron;

  /// Why the expression is invalid, when it is.
  final CronFormatException? error;

  /// The field under the cursor, whose allowed values the reference shows;
  /// `null` when the field is not being edited or for an `@` shortcut.
  final CronField? activeField;

  /// Where each field is written in [expression], in [CronField] order.
  final List<CronSpan> fieldSpans;

  /// Whether there is an expression to copy or clear.
  bool get hasExpression => expression.trim().isNotEmpty;

  CronState copyWith({CronModel? cron, CronField? activeField}) {
    return CronState(
      expression: expression,
      cron: cron ?? this.cron,
      error: error,
      activeField: activeField ?? this.activeField,
      fieldSpans: fieldSpans,
    );
  }

  /// This state with the cursor out of the expression.
  CronState withoutActiveField() => CronState(
    expression: expression,
    cron: cron,
    error: error,
    fieldSpans: fieldSpans,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CronState &&
          other.expression == expression &&
          other.cron == cron &&
          other.error == error &&
          other.activeField == activeField &&
          listEquals(other.fieldSpans, fieldSpans));

  @override
  int get hashCode => Object.hash(
    expression,
    cron,
    error,
    activeField,
    Object.hashAll(fieldSpans),
  );

  @override
  String toString() =>
      'CronState("$expression", cron: $cron, error: $error, '
      'activeField: ${activeField?.name})';
}
