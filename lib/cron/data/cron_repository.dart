import 'dart:math';

import 'cron_description.dart';
import 'cron_field.dart';
import 'cron_model.dart';
import 'cron_schedule.dart';

/// Explains cron expressions and makes up random ones, in the spirit of
/// crontab.guru.
class CronRepository {
  CronRepository({Random? random, DateTime Function()? clock})
    : _random = random ?? Random(),
      _clock = clock ?? DateTime.now;

  final Random _random;
  final DateTime Function() _clock;

  /// How many upcoming runs [explain] lists.
  static const nextRunCount = 5;

  /// Describes [expression] and computes its next runs from now.
  ///
  /// Throws a [CronFormatException] when cron would reject it.
  CronModel explain(String expression) {
    final schedule = CronSchedule.parse(expression);
    return CronModel(
      expression: expression.trim(),
      description: describeCron(schedule),
      equivalent: schedule.macro?.expression,
      nextRuns: schedule.nextRuns(_clock(), count: nextRunCount),
      atReboot: schedule.atReboot,
    );
  }

  /// Where each of the (up to five) fields of [expression] is written, so
  /// the UI can select one. Empty for an `@` shortcut, which has no fields.
  List<CronSpan> fieldSpans(String expression) {
    if (_isMacro(expression)) return const [];
    return [
      for (final word in CronSchedule.tokenize(
        expression,
      ).take(CronField.values.length))
        (start: word.start, end: word.end),
    ];
  }

  /// The field being edited with the cursor at [offset]: the word it touches,
  /// or the next one to be typed when it sits on the spaces between them.
  CronField? fieldAt(String expression, int offset) {
    if (_isMacro(expression)) return null;

    var index = 0;
    for (final word in CronSchedule.tokenize(expression)) {
      if (offset <= word.end) break;
      index++;
    }
    return index < CronField.values.length ? CronField.values[index] : null;
  }

  /// A random, valid and plausible expression: mostly fixed minutes, some
  /// steps and ranges, and date fields left as `*` most of the time.
  String random() => [
    _randomField(
      CronField.minute,
      any: 1,
      value: 10,
      step: 5,
      range: 1,
      list: 3,
      steps: const [2, 5, 10, 15, 20, 30],
    ),
    _randomField(
      CronField.hour,
      any: 6,
      value: 8,
      step: 3,
      range: 2,
      list: 1,
      steps: const [2, 3, 4, 6, 8, 12],
    ),
    _randomField(
      CronField.dayOfMonth,
      any: 14,
      value: 3,
      step: 1,
      range: 1,
      list: 1,
      steps: const [2, 3, 5, 7, 10, 15],
    ),
    _randomField(
      CronField.month,
      any: 15,
      value: 2,
      step: 2,
      range: 1,
      list: 0,
      steps: const [2, 3, 4, 6],
    ),
    _randomField(
      CronField.dayOfWeek,
      any: 12,
      value: 3,
      step: 0,
      range: 3,
      list: 2,
      steps: const [2],
    ),
  ].join(' ');

  /// One field, picking `*`, a value, a step, a range or a list with the
  /// given weights.
  String _randomField(
    CronField field, {
    required int any,
    required int value,
    required int step,
    required int range,
    required int list,
    required List<int> steps,
  }) {
    // Days up to 28 exist in every month, so a random date always comes.
    final low = field.min;
    final high = switch (field) {
      CronField.dayOfMonth => 28,
      CronField.dayOfWeek => 6,
      _ => field.max,
    };
    int between(int min, int max) => min + _random.nextInt(max - min + 1);

    final roll = _random.nextInt(any + value + step + range + list);
    if (roll < any) return '*';
    if (roll < any + value) return '${between(low, high)}';
    if (roll < any + value + step) {
      return '*/${steps[_random.nextInt(steps.length)]}';
    }
    if (roll < any + value + step + range) {
      final start = between(low, high - 1);
      return '$start-${between(start + 1, high)}';
    }
    final values = {for (var i = 0; i < 3; i++) between(low, high)}.toList()
      ..sort();
    return values.join(',');
  }

  bool _isMacro(String expression) => expression.trimLeft().startsWith('@');
}
