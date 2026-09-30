import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/cron/data/cron_field.dart';
import 'package:fake_generator/cron/data/cron_macro.dart';
import 'package:fake_generator/cron/data/cron_schedule.dart';

/// Tuesday, September 29, 2026, 10:00.
final _now = DateTime(2026, 9, 29, 10);

List<DateTime> _runs(String expression, {int count = 3}) =>
    CronSchedule.parse(expression).nextRuns(_now, count: count);

/// The field [expression] is rejected for.
CronField? _errorField(String expression) {
  try {
    CronSchedule.parse(expression);
  } on CronFormatException catch (error) {
    return error.field;
  }
  fail('"$expression" should be invalid');
}

void main() {
  group('CronSchedule.parse', () {
    test('expands every kind of item into sorted values', () {
      final schedule = CronSchedule.parse('1,5-7,*/20 */6 1-15/7 * *');

      expect(schedule.minute.values, [0, 1, 5, 6, 7, 20, 40]);
      expect(schedule.hour.values, [0, 6, 12, 18]);
      expect(schedule.dayOfMonth.values, [1, 8, 15]);
      expect(schedule.month.values, hasLength(12));
    });

    test('accepts a start with a step, up to the end of the field', () {
      expect(CronSchedule.parse('5/15 * * * *').minute.values, [5, 20, 35, 50]);
    });

    test('accepts month and weekday names, in any case', () {
      final schedule = CronSchedule.parse('0 0 * jan-Mar,DEC mon-fri');

      expect(schedule.month.values, [1, 2, 3, 12]);
      expect(schedule.dayOfWeek.values, [1, 2, 3, 4, 5]);
    });

    test('treats 7 as Sunday', () {
      expect(CronSchedule.parse('0 0 * * 7').dayOfWeek.values, [0]);
      expect(CronSchedule.parse('0 0 * * 5-7').dayOfWeek.values, [0, 5, 6]);
    });

    test('ignores extra spaces around and between the fields', () {
      expect(CronSchedule.parse('  5   4 * *  * ').hour.values, [4]);
    });

    test('expands the @ shortcuts', () {
      final daily = CronSchedule.parse('@daily');
      expect(daily.macro, CronMacro.daily);
      expect(daily.minute.values, [0]);
      expect(daily.hour.values, [0]);

      final reboot = CronSchedule.parse('@REBOOT');
      expect(reboot.atReboot, isTrue);
      expect(reboot.fields, isEmpty);
    });

    test('points at the first missing field', () {
      expect(_errorField('5 4 *'), CronField.month);
      expect(_errorField('5'), CronField.hour);
    });

    test('points at the field with a bad value', () {
      expect(_errorField('60 * * * *'), CronField.minute);
      expect(_errorField('* 24 * * *'), CronField.hour);
      expect(_errorField('* * 0 * *'), CronField.dayOfMonth);
      expect(_errorField('* * * 13 *'), CronField.month);
      expect(_errorField('* * * * 8'), CronField.dayOfWeek);
      expect(_errorField('* * * FOO *'), CronField.month);
      expect(_errorField('* * * * JAN'), CronField.dayOfWeek);
    });

    test('rejects malformed items', () {
      for (final expression in [
        '*/0 * * * *', // zero step
        '*/60 * * * *', // step larger than the field
        '5-1 * * * *', // reversed range
        '1,,2 * * * *', // empty item
        '1- * * * *', // open range
        '1-2-3 * * * *',
        '/5 * * * *',
        '1/2/3 * * * *',
        '1.5 * * * *',
        '-1 * * * *',
      ]) {
        expect(_errorField(expression), CronField.minute, reason: expression);
      }
    });

    test('rejects the expression as a whole when it has too much', () {
      expect(_errorField('5 4 * * * *'), isNull);
      expect(_errorField('@daily 5'), isNull);
      expect(_errorField('@sometimes'), isNull);
    });

    test('explains what is wrong', () {
      expect(
        () => CronSchedule.parse('60 * * * *'),
        throwsA(
          const CronFormatException(
            '60 está fora do intervalo de minuto: 0-59.',
            field: CronField.minute,
          ),
        ),
      );
    });
  });

  group('CronSchedule.missingSpaces', () {
    /// [expression] with the missing spaces put in.
    String spaced(String expression) {
      final text = StringBuffer();
      var from = 0;
      for (final at in CronSchedule.missingSpaces(expression)) {
        text
          ..write(expression.substring(from, at))
          ..write(' ');
        from = at;
      }
      return (text..write(expression.substring(from))).toString();
    }

    test('separates fields typed together', () {
      expect(spaced('*****'), '* * * * *');
      expect(spaced('*/5****'), '*/5 * * * *');
      expect(spaced('0 9**1-5'), '0 9 * * 1-5');
      expect(spaced('0 0*JAN*'), '0 0 * JAN *');
      expect(spaced('0 0 1 1MON'), '0 0 1 1 MON');
      expect(spaced('0 0 * JAN5'), '0 0 * JAN 5');
    });

    test('keeps each field whole', () {
      for (final expression in [
        '15 4 * * *',
        '*/15 0-20/2 1,15 JAN-MAR MON-FRI',
        '5,* * * * *',
        '',
        '*',
      ]) {
        expect(
          CronSchedule.missingSpaces(expression),
          isEmpty,
          reason: expression,
        );
      }
    });

    test('leaves @ shortcuts alone', () {
      expect(CronSchedule.missingSpaces('@daily'), isEmpty);
      expect(CronSchedule.missingSpaces('@hourly5*'), isEmpty);
    });
  });

  group('CronSchedule.nextRuns', () {
    test('lists the next runs after now, in order', () {
      expect(_runs('5 4 * * *'), [
        DateTime(2026, 9, 30, 4, 5),
        DateTime(2026, 10, 1, 4, 5),
        DateTime(2026, 10, 2, 4, 5),
      ]);
      expect(_runs('*/20 * * * *'), [
        DateTime(2026, 9, 29, 10, 20),
        DateTime(2026, 9, 29, 10, 40),
        DateTime(2026, 9, 29, 11),
      ]);
    });

    test('never returns now itself', () {
      expect(_runs('0 10 * * *', count: 1), [DateTime(2026, 9, 30, 10)]);
    });

    test('crosses months and years', () {
      expect(_runs('0 0 1 */4 *'), [
        DateTime(2027, 1, 1),
        DateTime(2027, 5, 1),
        DateTime(2027, 9, 1),
      ]);
    });

    test('runs on either day when both day fields are restricted', () {
      // Day 1 or Monday.
      expect(_runs('0 0 1 * 1', count: 4), [
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 5),
        DateTime(2026, 10, 12),
        DateTime(2026, 10, 19),
      ]);
    });

    test('requires both days when one of them starts with *', () {
      // Odd days of the month that are also Mondays.
      expect(_runs('0 0 */2 * 1'), [
        DateTime(2026, 10, 5),
        DateTime(2026, 10, 19),
        DateTime(2026, 11, 9),
      ]);
    });

    test('waits for February 29', () {
      expect(_runs('0 0 29 2 *', count: 2), [
        DateTime(2028, 2, 29),
        DateTime(2032, 2, 29),
      ]);
    });

    test('returns nothing for a date that never exists', () {
      expect(_runs('0 0 30 2 *'), isEmpty);
      expect(_runs('0 0 31 4,6,9,11 *'), isEmpty);
    });

    test('returns nothing for @reboot', () {
      expect(_runs('@reboot'), isEmpty);
    });
  });
}
