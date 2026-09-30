/// The five fields of a cron expression, in the order they are written.
///
/// Each field carries its range and the names accepted in place of numbers,
/// so the parser, the random generator and the reference table share one
/// source of truth for the limits (like `LoremUnit` for Lorem Ipsum).
enum CronField {
  minute(label: 'minuto', min: 0, max: 59),
  hour(label: 'hora', min: 0, max: 23),
  dayOfMonth(label: 'dia (mês)', min: 1, max: 31),
  month(
    label: 'mês',
    min: 1,
    max: 12,
    names: [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ],
  ),

  /// 0 and 7 are both Sunday: 7 is a non-standard alias most crons accept.
  dayOfWeek(
    label: 'dia (semana)',
    min: 0,
    max: 7,
    names: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'],
  );

  const CronField({
    required this.label,
    required this.min,
    required this.max,
    this.names = const [],
  });

  /// Short name shown under the expression and in error messages.
  final String label;

  /// Smallest value accepted.
  final int min;

  /// Largest value accepted, also the largest step (as in Vixie cron).
  final int max;

  /// English abbreviations accepted instead of numbers, for [min] onwards.
  final List<String> names;

  /// The numeric range shown in the reference table. Day of week leaves the
  /// Sunday alias out: it is listed on its own.
  String get allowedValues => '$min-${this == dayOfWeek ? 6 : max}';

  /// The number [name] stands for (case-insensitive), or `null`.
  int? valueOf(String name) {
    final index = names.indexOf(name.toUpperCase());
    return index < 0 ? null : min + index;
  }

  /// Folds aliases into one value: 7 becomes 0 (Sunday) on day of week.
  int normalize(int value) => this == dayOfWeek ? value % 7 : value;
}
