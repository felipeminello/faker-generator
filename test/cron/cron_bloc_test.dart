import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/cron/bloc/cron_bloc.dart';
import 'package:fake_generator/cron/data/cron_field.dart';
import 'package:fake_generator/cron/data/cron_repository.dart';
import 'package:fake_generator/cron/data/cron_schedule.dart';

/// The real parser and descriptions, with a clock the tests can move and a
/// "random" expression they know in advance.
class _FakeCronRepository extends CronRepository {
  _FakeCronRepository() : super(clock: () => _FakeCronRepository.now);

  static DateTime now = DateTime(2026, 9, 29, 10);

  @override
  String random() => '*/15 * * * *';
}

void main() {
  group('CronBloc', () {
    late _FakeCronRepository repository;

    setUp(() {
      _FakeCronRepository.now = DateTime(2026, 9, 29, 10);
      repository = _FakeCronRepository();
    });

    CronBloc build() => CronBloc(repository);

    test('starts empty', () {
      final bloc = build();

      expect(bloc.state, const CronState());
      expect(bloc.state.hasExpression, isFalse);
    });

    blocTest<CronBloc, CronState>(
      'explains a valid expression as it is typed',
      build: build,
      act: (bloc) => bloc.add(const CronExpressionChanged('5 4 * * *')),
      verify: (bloc) {
        final state = bloc.state;
        expect(state.expression, '5 4 * * *');
        expect(state.cron?.description, 'Às 04:05.');
        expect(state.cron?.nextRuns.first, DateTime(2026, 9, 30, 4, 5));
        expect(state.error, isNull);
        expect(state.fieldSpans, hasLength(5));
      },
    );

    blocTest<CronBloc, CronState>(
      'reports why an invalid expression fails, and in which field',
      build: build,
      act: (bloc) => bloc.add(const CronExpressionChanged('5 25 * * *')),
      verify: (bloc) {
        expect(bloc.state.cron, isNull);
        expect(bloc.state.error?.field, CronField.hour);
        expect(bloc.state.hasExpression, isTrue);
      },
    );

    blocTest<CronBloc, CronState>(
      'a blank expression is the empty state, not an error',
      build: build,
      act: (bloc) => bloc.add(const CronExpressionChanged('   ')),
      verify: (bloc) {
        expect(bloc.state.cron, isNull);
        expect(bloc.state.error, isNull);
        expect(bloc.state.hasExpression, isFalse);
      },
    );

    blocTest<CronBloc, CronState>(
      'ignores a change that does not change the text',
      build: build,
      seed: () => const CronState(expression: '* * * * *'),
      act: (bloc) => bloc.add(const CronExpressionChanged('* * * * *')),
      expect: () => const <CronState>[],
    );

    blocTest<CronBloc, CronState>(
      'generates a random expression',
      build: build,
      act: (bloc) => bloc.add(const CronRequested()),
      verify: (bloc) {
        expect(bloc.state.expression, '*/15 * * * *');
        expect(bloc.state.cron?.description, 'A cada 15 minutos.');
      },
    );

    blocTest<CronBloc, CronState>(
      'clearing returns to the empty state',
      build: build,
      act: (bloc) => bloc
        ..add(const CronExpressionChanged('bad'))
        ..add(const CronCleared()),
      verify: (bloc) => expect(bloc.state, const CronState()),
    );

    blocTest<CronBloc, CronState>(
      'follows the field under the cursor',
      build: build,
      act: (bloc) => bloc
        ..add(const CronExpressionChanged('*/5 4 * * *'))
        ..add(const CronCursorMoved(2))
        ..add(const CronCursorMoved(3)) // same field: no new state
        ..add(const CronCursorMoved(5))
        ..add(const CronCursorMoved(null)),
      expect: () => [
        isA<CronState>().having((s) => s.activeField, 'field', isNull),
        isA<CronState>().having(
          (s) => s.activeField,
          'field',
          CronField.minute,
        ),
        isA<CronState>().having((s) => s.activeField, 'field', CronField.hour),
        isA<CronState>().having((s) => s.activeField, 'field', isNull),
      ],
    );

    blocTest<CronBloc, CronState>(
      'keeps the field under the cursor when the text changes',
      build: build,
      act: (bloc) => bloc
        ..add(const CronCursorMoved(0))
        ..add(const CronExpressionChanged('5')),
      verify: (bloc) => expect(bloc.state.activeField, CronField.minute),
    );

    blocTest<CronBloc, CronState>(
      'refreshing moves the next runs past the new now',
      build: build,
      act: (bloc) async {
        bloc.add(const CronExpressionChanged('0 * * * *'));
        await Future<void>.delayed(Duration.zero);
        _FakeCronRepository.now = DateTime(2026, 9, 29, 15, 30);
        bloc.add(const CronRefreshed());
      },
      verify: (bloc) {
        expect(bloc.state.cron?.nextRuns.first, DateTime(2026, 9, 29, 16));
      },
    );

    blocTest<CronBloc, CronState>(
      'refreshing without a valid expression does nothing',
      build: build,
      act: (bloc) => bloc.add(const CronRefreshed()),
      expect: () => const <CronState>[],
    );

    blocTest<CronBloc, CronState>(
      'its errors carry the message shown to the user',
      build: build,
      act: (bloc) => bloc.add(const CronExpressionChanged('*/0 * * * *')),
      verify: (bloc) => expect(
        bloc.state.error,
        const CronFormatException(
          'Incremento inválido em minuto: “0”. Use um número de 1 a 59.',
          field: CronField.minute,
        ),
      ),
    );
  });
}
