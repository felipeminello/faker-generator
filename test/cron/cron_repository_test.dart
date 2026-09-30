import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/cron/data/cron_field.dart';
import 'package:fake_generator/cron/data/cron_repository.dart';
import 'package:fake_generator/cron/data/cron_schedule.dart';

/// Tuesday, September 29, 2026, 10:00.
DateTime _now() => DateTime(2026, 9, 29, 10);

void main() {
  group('CronRepository.explain', () {
    final repository = CronRepository(clock: _now);

    test('describes expressions in Portuguese', () {
      const descriptions = {
        '5 4 * * *': 'Às 04:05.',
        '30 1 * * *': 'À 01:30.',
        '* * * * *': 'A cada minuto.',
        '*/5 * * * *': 'A cada 5 minutos.',
        '0 * * * *': 'No minuto 0.',
        '5,10 * * * *': 'Nos minutos 5 e 10.',
        '5-10 * * * *': 'A cada minuto de 5 a 10.',
        '5/15 * * * *': 'A cada 15 minutos a partir do minuto 5.',
        '1,5-10,*/20 * * * *':
            'No minuto 1, a cada minuto de 5 a 10 e a cada 20 minutos.',
        '* 4 * * *': 'A cada minuto na hora 4.',
        '0 */2 * * *': 'No minuto 0 a cada 2 horas.',
        '23 0-20/2 * * *': 'No minuto 23 a cada 2 horas de 0 a 20.',
        '0,30 8,12 * * *': 'Às 08:00, 08:30, 12:00 e 12:30.',
        '0 0 * * 0': 'Às 00:00, aos domingos.',
        '0 22 * * 1-5': 'Às 22:00, de segunda-feira a sexta-feira.',
        '0 8 * * sat,sun': 'Às 08:00, aos domingos e aos sábados.',
        '*/15 9-17 * * mon-fri':
            'A cada 15 minutos nas horas de 9 a 17, de segunda-feira a '
            'sexta-feira.',
        '0 4 8-14 * *': 'Às 04:00, nos dias 8 a 14 do mês.',
        '0 0 1,15 * *': 'Às 00:00, nos dias 1 e 15 do mês.',
        '0 0 */2 * *': 'Às 00:00, a cada 2 dias do mês.',
        '0 0 1 1 *': 'Às 00:00, no dia 1 do mês, em janeiro.',
        '0 0 1 */3 *': 'Às 00:00, no dia 1 do mês, a cada 3 meses.',
        '0 12 * jan-mar,jul *': 'Às 12:00, de janeiro a março e em julho.',
        '0 0 1 * 1': 'Às 00:00, no dia 1 do mês e às segundas-feiras.',
        '0 0 */2 * 1':
            'Às 00:00, a cada 2 dias do mês, apenas às segundas-feiras.',
        '@weekly': 'Às 00:00, aos domingos.',
        '@reboot': 'Após reiniciar o sistema.',
      };

      descriptions.forEach((expression, description) {
        expect(
          repository.explain(expression).description,
          description,
          reason: expression,
        );
      });
    });

    test('lists the next five runs from now', () {
      final cron = repository.explain('  5 4 * * *  ');

      expect(cron.expression, '5 4 * * *');
      expect(cron.nextRuns, [
        for (var day = 30; day < 35; day++) DateTime(2026, 9, day, 4, 5),
      ]);
      expect(cron.neverRuns, isFalse);
    });

    test('shows what an @ shortcut stands for', () {
      expect(repository.explain('@daily').equivalent, '0 0 * * *');
      expect(repository.explain('0 0 * * *').equivalent, isNull);
    });

    test('tells @reboot apart from a date that never comes', () {
      final reboot = repository.explain('@reboot');
      expect(reboot.atReboot, isTrue);
      expect(reboot.neverRuns, isFalse);

      final never = repository.explain('0 0 30 2 *');
      expect(never.nextRuns, isEmpty);
      expect(never.neverRuns, isTrue);
    });

    test('throws for an invalid expression', () {
      expect(
        () => repository.explain('* * * * 8'),
        throwsA(
          isA<CronFormatException>().having(
            (error) => error.field,
            'field',
            CronField.dayOfWeek,
          ),
        ),
      );
    });
  });

  group('CronRepository.random', () {
    test('always makes a valid expression that runs', () {
      final repository = CronRepository(random: Random(42), clock: _now);

      for (var i = 0; i < 500; i++) {
        final expression = repository.random();
        final cron = repository.explain(expression);
        expect(cron.nextRuns, isNotEmpty, reason: expression);
      }
    });

    test('varies', () {
      final repository = CronRepository(random: Random(7));

      expect(
        {for (var i = 0; i < 20; i++) repository.random()}.length,
        greaterThan(15),
      );
    });

    test('is deterministic with a seeded Random', () {
      expect(
        CronRepository(random: Random(3)).random(),
        CronRepository(random: Random(3)).random(),
      );
    });
  });

  group('CronRepository fields', () {
    final repository = CronRepository();

    test('finds where each field is written', () {
      expect(repository.fieldSpans('5  4 * '), [
        (start: 0, end: 1),
        (start: 3, end: 4),
        (start: 5, end: 6),
      ]);
      expect(repository.fieldSpans('@daily'), isEmpty);
    });

    test('knows which field the cursor is on', () {
      const expression = '*/5 4 * * *';

      expect(repository.fieldAt(expression, 0), CronField.minute);
      expect(repository.fieldAt(expression, 3), CronField.minute);
      expect(repository.fieldAt(expression, 4), CronField.hour);
      expect(repository.fieldAt(expression, 11), CronField.dayOfWeek);
    });

    test('picks the next field while it is being typed', () {
      expect(repository.fieldAt('', 0), CronField.minute);
      expect(repository.fieldAt('5 4 ', 4), CronField.dayOfMonth);
      expect(repository.fieldAt('5 4 * * * ', 10), isNull);
    });

    test('has no field for an @ shortcut', () {
      expect(repository.fieldAt('@daily', 2), isNull);
    });
  });
}
