/// The non-standard `@` shortcuts that replace the five fields.
enum CronMacro {
  yearly('@yearly', '0 0 1 1 *'),
  annually('@annually', '0 0 1 1 *'),
  monthly('@monthly', '0 0 1 * *'),
  weekly('@weekly', '0 0 * * 0'),
  daily('@daily', '0 0 * * *'),
  midnight('@midnight', '0 0 * * *'),
  hourly('@hourly', '0 * * * *'),

  /// Runs once, when the cron daemon starts: it has no time at all.
  reboot('@reboot', null);

  const CronMacro(this.keyword, this.expression);

  /// What is written in the crontab, such as `@daily`.
  final String keyword;

  /// The five-field expression this shortcut stands for, or `null` for
  /// [reboot].
  final String? expression;

  /// The shortcut spelled [keyword] (case-insensitive), or `null`.
  static CronMacro? fromKeyword(String keyword) {
    final lower = keyword.toLowerCase();
    for (final macro in values) {
      if (macro.keyword == lower) return macro;
    }
    return null;
  }
}
