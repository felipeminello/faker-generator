import 'package:flutter/foundation.dart';

/// A valid cron expression, explained: what it means and when it runs next.
class CronModel {
  const CronModel({
    required this.expression,
    required this.description,
    this.equivalent,
    this.nextRuns = const [],
    this.atReboot = false,
  });

  /// The expression as written, without surrounding spaces.
  final String expression;

  /// What the expression means, such as "Às 04:05.".
  final String description;

  /// The five fields an `@` shortcut stands for (`@daily` is `0 0 * * *`),
  /// or `null` for a five-field expression.
  final String? equivalent;

  /// The next times it fires, in local time. Empty for `@reboot` and for
  /// dates that never exist.
  final List<DateTime> nextRuns;

  /// Whether this is `@reboot`, which fires when the system starts.
  final bool atReboot;

  /// Whether it has a time but the date never comes, such as February 30.
  bool get neverRuns => !atReboot && nextRuns.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CronModel &&
          other.expression == expression &&
          other.description == description &&
          other.equivalent == equivalent &&
          listEquals(other.nextRuns, nextRuns) &&
          other.atReboot == atReboot);

  @override
  int get hashCode => Object.hash(
    expression,
    description,
    equivalent,
    Object.hashAll(nextRuns),
    atReboot,
  );

  @override
  String toString() =>
      'CronModel($expression, "$description", next: ${nextRuns.firstOrNull})';
}
