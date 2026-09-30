import 'cron_schedule.dart';
import 'cron_text.dart';

/// Explains [schedule] in Portuguese, in the spirit of crontab.guru:
/// "Às 04:05.", "A cada 15 minutos nas horas de 9 a 17, de segunda-feira a
/// sexta-feira.".
///
/// The sentence follows the fields: the time (minute and hour), then the
/// days (day of month and day of week), then the months.
String describeCron(CronSchedule schedule) {
  if (schedule.atReboot) return 'Após reiniciar o sistema.';

  final sentence = [
    _time(schedule.minute, schedule.hour),
    _days(schedule.dayOfMonth, schedule.dayOfWeek),
    if (!schedule.month.isAny) _phrase(schedule.month, _monthWords),
  ].where((clause) => clause.isNotEmpty).join(', ');

  return '${sentence[0].toUpperCase()}${sentence.substring(1)}.';
}

/// "às 04:05" when minute and hour are plain values (a few combinations at
/// most); otherwise the minute phrase followed by the hour phrase.
String _time(CronFieldValue minute, CronFieldValue hour) {
  final minutes = _plainValues(minute);
  final hours = _plainValues(hour);

  if (minutes != null && hours != null && minutes.length * hours.length <= 6) {
    final times = [
      for (final h in hours)
        for (final m in minutes) '${twoDigits(h)}:${twoDigits(m)}',
    ];
    // "à 01:30" (a uma hora), but "às 00:00", "às 04:05", "às 01:00 e 13:00".
    final article = times.length == 1 && hours.single == 1 ? 'à' : 'às';
    return '$article ${joinWords(times)}';
  }

  final minutePhrase = _phrase(minute, _minuteWords);
  return hour.isAny
      ? minutePhrase
      : '$minutePhrase ${_phrase(hour, _hourWords)}';
}

String _days(CronFieldValue dayOfMonth, CronFieldValue dayOfWeek) {
  if (dayOfWeek.isAny) {
    return dayOfMonth.isAny ? '' : _phrase(dayOfMonth, _dayWords);
  }
  final weekdays = _phrase(dayOfWeek, _weekdayWords);
  if (dayOfMonth.isAny) return weekdays;

  // Both restricted: cron runs on either, unless one starts with `*` (see
  // CronSchedule.runsOn), and then only on days matching both.
  final days = _phrase(dayOfMonth, _dayWords);
  return dayOfMonth.isStar || dayOfWeek.isStar
      ? '$days, apenas $weekdays'
      : '$days e $weekdays';
}

/// The values of [field] when it is only a list of plain values (`5`,
/// `1,15`), or `null` when it has ranges, steps or `*`.
List<int>? _plainValues(CronFieldValue field) =>
    field.parts.every((part) => part is CronValue) ? field.values : null;

String _phrase(CronFieldValue field, _Words words) {
  final values = _plainValues(field);
  final String text;
  if (field.isAny) {
    text = words.every;
  } else if (values != null) {
    text = values.length == 1 ? words.one(values.single) : words.many(values);
  } else {
    text = joinWords([for (final part in field.parts) _item(part, words)]);
  }
  return '$text${words.suffix}';
}

String _item(CronPart part, _Words words) => switch (part) {
  CronAny() => words.every,
  CronValue(:final value) => words.one(value),
  CronRange(:final start, :final end) => words.range(
    words.name(start),
    words.name(end),
  ),
  CronStep(:final base, :final step) => _step(base, step, words),
};

String _step(CronPart base, int step, _Words words) {
  final every = step == 1 ? words.every : words.everyN(step);
  return switch (base) {
    CronRange(:final start, :final end) =>
      step == 1
          ? words.range(words.name(start), words.name(end))
          : words.stepRange(every, words.name(start), words.name(end)),
    CronValue(:final value) => words.stepFrom(every, words.name(value)),
    _ => every,
  };
}

/// How one field is put into words.
class _Words {
  const _Words({
    required this.every,
    required this.everyN,
    required this.one,
    required this.many,
    required this.range,
    required this.stepRange,
    required this.stepFrom,
    this.name = _number,
    this.suffix = '',
  });

  /// `*`: "a cada minuto".
  final String every;

  /// `*/n`: "a cada 5 minutos".
  final String Function(int step) everyN;

  /// `5`: "no minuto 5".
  final String Function(int value) one;

  /// `5,10`: "nos minutos 5 e 10".
  final String Function(List<int> values) many;

  /// `5-10`: "a cada minuto de 5 a 10".
  final String Function(String start, String end) range;

  /// `5-10/2`: [everyN] followed by "de 5 a 10".
  final String Function(String every, String start, String end) stepRange;

  /// `5/2`: [everyN] followed by "a partir do minuto 5".
  final String Function(String every, String start) stepFrom;

  /// How a value is written: a number, or a month or day name.
  final String Function(int value) name;

  /// Appended to the whole phrase: " do mês".
  final String suffix;
}

String _number(int value) => '$value';

String _numbers(List<int> values) => joinWords(values.map(_number));

final _minuteWords = _Words(
  every: 'a cada minuto',
  everyN: (step) => 'a cada $step minutos',
  one: (value) => 'no minuto $value',
  many: (values) => 'nos minutos ${_numbers(values)}',
  range: (start, end) => 'a cada minuto de $start a $end',
  stepRange: (every, start, end) => '$every de $start a $end',
  stepFrom: (every, start) => '$every a partir do minuto $start',
);

final _hourWords = _Words(
  every: 'a cada hora',
  everyN: (step) => 'a cada $step horas',
  one: (value) => 'na hora $value',
  many: (values) => 'nas horas ${_numbers(values)}',
  range: (start, end) => 'nas horas de $start a $end',
  stepRange: (every, start, end) => '$every de $start a $end',
  stepFrom: (every, start) => '$every a partir da hora $start',
);

final _dayWords = _Words(
  every: 'todos os dias',
  everyN: (step) => 'a cada $step dias',
  one: (value) => 'no dia $value',
  many: (values) => 'nos dias ${_numbers(values)}',
  range: (start, end) => 'nos dias $start a $end',
  stepRange: (every, start, end) => '$every entre os dias $start e $end',
  stepFrom: (every, start) => '$every a partir do dia $start',
  suffix: ' do mês',
);

final _monthWords = _Words(
  every: 'todos os meses',
  everyN: (step) => 'a cada $step meses',
  one: (value) => 'em ${monthNames[value - 1]}',
  many: (values) =>
      'em ${joinWords(values.map((value) => monthNames[value - 1]))}',
  range: (start, end) => 'de $start a $end',
  stepRange: (every, start, end) => '$every de $start a $end',
  stepFrom: (every, start) => '$every a partir de $start',
  name: (value) => monthNames[value - 1],
);

final _weekdayWords = _Words(
  every: 'todos os dias da semana',
  everyN: (step) => 'a cada $step dias da semana',
  one: _onWeekday,
  many: (values) => joinWords(values.map(_onWeekday)),
  range: (start, end) => 'de $start a $end',
  stepRange: (every, start, end) => '$every de $start a $end',
  stepFrom: (every, start) => '$every a partir de $start',
  name: (value) => weekdayNames[value % 7],
);

/// "aos domingos", "às segundas-feiras".
String _onWeekday(int value) {
  final day = value % 7;
  final article = day == 0 || day == 6 ? 'aos' : 'às';
  return '$article ${weekdayPlurals[day]}';
}
