import 'cron_field.dart';
import 'cron_macro.dart';
import 'cron_text.dart';

/// Thrown by [CronSchedule.parse] for an expression cron would reject.
class CronFormatException implements Exception {
  const CronFormatException(this.message, {this.field});

  /// Explanation shown to the user, in Portuguese.
  final String message;

  /// The field at fault, or `null` when the problem is the expression as a
  /// whole (too many fields, unknown shortcut).
  final CronField? field;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CronFormatException &&
          other.message == message &&
          other.field == field);

  @override
  int get hashCode => Object.hash(message, field);

  @override
  String toString() => 'CronFormatException(${field?.name}: $message)';
}

/// One comma-separated item of a field.
sealed class CronPart {
  const CronPart();
}

/// `*`: every value of the field.
final class CronAny extends CronPart {
  const CronAny();
}

/// A single value, such as `5` or `MON`.
final class CronValue extends CronPart {
  const CronValue(this.value);

  final int value;
}

/// An inclusive range, such as `1-5` or `MON-FRI`.
final class CronRange extends CronPart {
  const CronRange(this.start, this.end);

  final int start;
  final int end;
}

/// Every [step]-th value of [base]: `*/15`, `0-30/5`, or `5/15` (from 5 up
/// to the end of the field, a common extension).
final class CronStep extends CronPart {
  const CronStep(this.base, this.step);

  /// A [CronAny], [CronRange] or [CronValue].
  final CronPart base;
  final int step;
}

/// Where a whitespace-separated word of an expression sits in the text.
typedef CronSpan = ({int start, int end});

/// One parsed field: what was written and the values it selects.
class CronFieldValue {
  CronFieldValue(this.field, this.source, this.parts)
    : values = _expand(field, parts);

  final CronField field;

  /// The field as written, such as `*/15`.
  final String source;

  /// The comma-separated items of [source].
  final List<CronPart> parts;

  /// Every value the field matches, normalized (day of week 7 is 0), sorted
  /// and without repetitions.
  final List<int> values;

  /// Whether one of the items is a bare `*`, so the field matches anything.
  bool get isAny => parts.any((part) => part is CronAny);

  /// Whether the field starts with `*` (`*`, `*/2`...). This, and not the
  /// values, is what cron checks to combine day of month and day of week.
  bool get isStar => source.startsWith('*');

  bool contains(int value) => values.contains(field.normalize(value));

  /// The first value that is [from] or more, or `null`.
  int? firstFrom(int from) {
    for (final value in values) {
      if (value >= from) return value;
    }
    return null;
  }

  static List<int> _expand(CronField field, List<CronPart> parts) {
    final values = <int>{};
    for (final part in parts) {
      final (start, end, step) = switch (part) {
        CronAny() => (field.min, field.max, 1),
        CronValue(:final value) => (value, value, 1),
        CronRange(:final start, :final end) => (start, end, 1),
        CronStep(:final base, :final step) => switch (base) {
          CronRange(:final start, :final end) => (start, end, step),
          CronValue(:final value) => (value, field.max, step),
          _ => (field.min, field.max, step),
        },
      };
      for (var value = start; value <= end; value += step) {
        values.add(field.normalize(value));
      }
    }
    return values.toList()..sort();
  }
}

/// A parsed cron expression: five fields, or one of the `@` shortcuts.
///
/// Follows Vixie cron, the implementation behind most Linux crontabs (and
/// the one crontab.guru describes): names like `JAN`/`MON`, 7 as Sunday,
/// steps no larger than the field, and day of month and day of week combined
/// with "or" when both are restricted.
class CronSchedule {
  const CronSchedule._({required this.fields, this.macro});

  /// Parses [expression], throwing a [CronFormatException] that says what is
  /// wrong (and in which field) when cron would reject it.
  factory CronSchedule.parse(String expression) {
    final words = tokenize(expression);
    if (words.isEmpty) {
      throw const CronFormatException('A expressão está vazia.');
    }

    final first = words.first.text;
    if (first.startsWith('@')) {
      final macro = CronMacro.fromKeyword(first);
      if (macro == null) {
        throw CronFormatException(
          'Atalho desconhecido: $first. Use '
          '${joinWords(CronMacro.values.map((macro) => macro.keyword), last: 'ou')}.',
        );
      }
      if (words.length > 1) {
        throw CronFormatException(
          '${macro.keyword} já substitui os 5 campos: não escreva nada depois '
          'dele.',
        );
      }
      final expansion = macro.expression;
      return CronSchedule._(
        fields: expansion == null
            ? const []
            : CronSchedule.parse(expansion).fields,
        macro: macro,
      );
    }

    if (words.length < CronField.values.length) {
      final missing = CronField.values.skip(words.length).toList();
      throw CronFormatException(
        missing.length == 1
            ? 'Falta 1 campo: ${missing.single.label}.'
            : 'Faltam ${missing.length} campos: '
                  '${joinWords(missing.map((field) => field.label))}.',
        field: missing.first,
      );
    }
    if (words.length > CronField.values.length) {
      throw CronFormatException(
        'Campos demais: o cron usa ${CronField.values.length}, e a expressão '
        'tem ${words.length}.',
      );
    }

    return CronSchedule._(
      fields: [
        for (final (index, field) in CronField.values.indexed)
          _parseField(field, words[index].text),
      ],
    );
  }

  /// The five fields, in [CronField] order; empty for `@reboot`.
  final List<CronFieldValue> fields;

  /// The shortcut the expression was written with, if any.
  final CronMacro? macro;

  CronFieldValue get minute => fields[0];
  CronFieldValue get hour => fields[1];
  CronFieldValue get dayOfMonth => fields[2];
  CronFieldValue get month => fields[3];
  CronFieldValue get dayOfWeek => fields[4];

  /// Whether this is `@reboot`, which has no time at all.
  bool get atReboot => macro == CronMacro.reboot;

  /// How far [nextRuns] looks ahead. Any date that exists at all comes back
  /// within that time: February 29 on a given weekday recurs within 40 years.
  static const searchYears = 50;

  /// The whitespace-separated words of [expression] and where each one sits.
  static List<({String text, int start, int end})> tokenize(
    String expression,
  ) => [
    for (final match in RegExp(r'\S+').allMatches(expression))
      (text: match[0]!, start: match.start, end: match.end),
  ];

  /// Where [expression] lacks the space between two fields typed together:
  /// the offsets before which one belongs, in order. `*****` needs four
  /// (`* * * * *`), `*/5*` one (`*/5 *`).
  ///
  /// Only where the two characters cannot share a field: a `*` touching
  /// another `*`, a number or a name, or a number touching a name. Numbers
  /// and names are left whole (`15` could not be told from `1 5`), and so is
  /// everything after an `@`, where a shortcut is being written.
  static List<int> missingSpaces(String expression) {
    if (expression.contains('@')) return const [];

    final offsets = <int>[];
    for (var i = 1; i < expression.length; i++) {
      final before = _kindOf(expression[i - 1]);
      final after = _kindOf(expression[i]);
      if (before == null || after == null) continue;
      if (before != after || before == _Kind.star) offsets.add(i);
    }
    return offsets;
  }

  static _Kind? _kindOf(String char) {
    if (char == '*') return _Kind.star;
    if (RegExp('[0-9]').hasMatch(char)) return _Kind.number;
    if (RegExp('[A-Za-z]').hasMatch(char)) return _Kind.name;
    return null;
  }

  /// Whether cron runs on this day, looking only at the date fields.
  ///
  /// When day of month and day of week are both restricted, cron runs on
  /// days matching either — unless one of them starts with `*`, and then both
  /// must match.
  bool runsOn(int year, int month, int day) {
    if (!this.month.contains(month)) return false;
    final byDate = dayOfMonth.contains(day);
    final byWeekday = dayOfWeek.contains(
      DateTime.utc(year, month, day).weekday,
    );
    return dayOfMonth.isStar || dayOfWeek.isStar
        ? byDate && byWeekday
        : byDate || byWeekday;
  }

  /// The next [count] times this schedule fires after [after], in local time.
  ///
  /// Fewer come back when the date never exists (such as `0 0 30 2 *`), and
  /// none for `@reboot`. The search walks the calendar fields instead of
  /// adding durations, so daylight saving changes cannot make it loop.
  List<DateTime> nextRuns(DateTime after, {required int count}) {
    if (atReboot) return const [];

    final runs = <DateTime>[];
    final lastYear = after.year + searchYears;
    var (year, month, day, hour, minute) = (
      after.year,
      after.month,
      after.day,
      after.hour,
      after.minute + 1,
    );

    while (runs.length < count) {
      if (minute > 59) (minute, hour) = (0, hour + 1);
      if (hour > 23) (hour, day) = (0, day + 1);
      if (month > 12) (month, year) = (1, year + 1);
      if (day > _daysIn(year, month)) {
        (day, month) = (1, month + 1);
        if (month > 12) (month, year) = (1, year + 1);
      }
      if (year > lastYear) break;

      if (!this.month.contains(month)) {
        (month, day, hour, minute) = (month + 1, 1, 0, 0);
        continue;
      }
      if (!runsOn(year, month, day)) {
        (day, hour, minute) = (day + 1, 0, 0);
        continue;
      }

      final nextHour = this.hour.firstFrom(hour);
      if (nextHour == null) {
        (day, hour, minute) = (day + 1, 0, 0);
        continue;
      }
      if (nextHour != hour) (hour, minute) = (nextHour, 0);

      final nextMinute = this.minute.firstFrom(minute);
      if (nextMinute == null) {
        (hour, minute) = (hour + 1, 0);
        continue;
      }

      runs.add(DateTime(year, month, day, hour, nextMinute));
      minute = nextMinute + 1;
    }

    return runs;
  }

  static int _daysIn(int year, int month) =>
      DateTime.utc(year, month + 1, 0).day;

  static CronFieldValue _parseField(CronField field, String source) =>
      CronFieldValue(field, source, [
        for (final item in source.split(',')) _parsePart(field, item, source),
      ]);

  static CronPart _parsePart(CronField field, String item, String source) {
    if (item.isEmpty) {
      throw CronFormatException(
        'Sobrou uma vírgula em ${field.label}: “$source”.',
        field: field,
      );
    }

    final pieces = item.split('/');
    if (pieces.length > 2) {
      throw CronFormatException(
        'Use só uma “/” por item em ${field.label}: “$item”.',
        field: field,
      );
    }
    if (pieces.first.isEmpty) {
      throw CronFormatException(
        'Falta o início antes da “/” em ${field.label}: “$item”. Para '
        '“a cada N”, use “*/N”.',
        field: field,
      );
    }

    final base = _parseBase(field, pieces.first);
    if (pieces.length == 1) return base;

    final step = RegExp(r'^\d+$').hasMatch(pieces.last)
        ? int.tryParse(pieces.last)
        : null;
    if (step == null || step < 1 || step > field.max) {
      throw CronFormatException(
        'Incremento inválido em ${field.label}: “${pieces.last}”. Use um '
        'número de 1 a ${field.max}.',
        field: field,
      );
    }
    return CronStep(base, step);
  }

  static CronPart _parseBase(CronField field, String text) {
    if (text == '*') return const CronAny();

    final ends = text.split('-');
    if (ends.length == 1) return CronValue(_parseValue(field, text));
    if (ends.length > 2 || ends.any((end) => end.isEmpty)) {
      throw CronFormatException(
        'Intervalo incompleto em ${field.label}: “$text”. Use início-fim, '
        'como “1-5”.',
        field: field,
      );
    }

    final start = _parseValue(field, ends.first);
    final end = _parseValue(field, ends.last);
    if (start > end) {
      throw CronFormatException(
        'Intervalo invertido em ${field.label}: “$text”. O início precisa ser '
        'menor ou igual ao fim.',
        field: field,
      );
    }
    return CronRange(start, end);
  }

  static int _parseValue(CronField field, String text) {
    final isNumber = RegExp(r'^\d+$').hasMatch(text);
    final value = isNumber ? int.tryParse(text) : field.valueOf(text);

    if (!isNumber && value == null) {
      final names = field.names.isEmpty
          ? ''
          : ' ou ${field.names.first}-${field.names.last}';
      throw CronFormatException(
        '“$text” não é um valor válido para ${field.label}: use '
        '${field.allowedValues}$names.',
        field: field,
      );
    }
    if (value == null || value < field.min || value > field.max) {
      throw CronFormatException(
        '$text está fora do intervalo de ${field.label}: '
        '${field.allowedValues}.',
        field: field,
      );
    }
    return value;
  }
}

/// What a character of a field can be part of, for [CronSchedule.missingSpaces].
/// Separators (`,` `-` `/`) and spaces are none of these.
enum _Kind { star, number, name }
