import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/lorem/bloc/lorem_bloc.dart';
import 'package:fake_generator/lorem/data/lorem_model.dart';
import 'package:fake_generator/lorem/data/lorem_repository.dart';
import 'package:fake_generator/lorem/data/lorem_unit.dart';

/// Echoes the options back as text, so the tests can assert which options a
/// generated text was produced with.
class _FakeLoremRepository implements LoremRepository {
  @override
  LoremModel generate({
    required LoremUnit unit,
    required int count,
    bool startWithLorem = true,
  }) {
    return LoremModel(
      text: '${unit.name}:$count:$startWithLorem',
      unit: unit,
      count: count,
    );
  }
}

LoremModel _model(LoremUnit unit, int count, {bool startWithLorem = true}) =>
    LoremModel(
      text: '${unit.name}:$count:$startWithLorem',
      unit: unit,
      count: count,
    );

void main() {
  group('LoremBloc', () {
    test('starts with 3 paragraphs, the opening on and no text', () {
      final bloc = LoremBloc(_FakeLoremRepository());

      expect(bloc.state, const LoremState());
      expect(bloc.state.unit, LoremUnit.paragraphs);
      expect(bloc.state.count, 3);
      expect(bloc.state.startWithLorem, isTrue);
      expect(bloc.state.hasText, isFalse);
    });

    blocTest<LoremBloc, LoremState>(
      'emits the generated text when LoremRequested is added',
      build: () => LoremBloc(_FakeLoremRepository()),
      act: (bloc) => bloc.add(const LoremRequested()),
      expect: () => [LoremState(lorem: _model(LoremUnit.paragraphs, 3))],
    );

    blocTest<LoremBloc, LoremState>(
      'switching the unit resets the amount to that unit default',
      build: () => LoremBloc(_FakeLoremRepository()),
      act: (bloc) => bloc.add(const LoremUnitChanged(LoremUnit.words)),
      expect: () => const [LoremState(unit: LoremUnit.words, count: 50)],
    );

    blocTest<LoremBloc, LoremState>(
      'clamps the amount to the range of the current unit',
      build: () => LoremBloc(_FakeLoremRepository()),
      act: (bloc) => bloc
        ..add(const LoremCountChanged(0))
        ..add(const LoremCountChanged(999)),
      expect: () => const [LoremState(count: 1), LoremState(count: 50)],
    );

    blocTest<LoremBloc, LoremState>(
      'regenerates the text when an option changes while it is on screen',
      build: () => LoremBloc(_FakeLoremRepository()),
      act: (bloc) => bloc
        ..add(const LoremRequested())
        ..add(const LoremCountChanged(5))
        ..add(const LoremOpeningToggled(false)),
      expect: () => [
        LoremState(lorem: _model(LoremUnit.paragraphs, 3)),
        LoremState(count: 5, lorem: _model(LoremUnit.paragraphs, 5)),
        LoremState(
          count: 5,
          startWithLorem: false,
          lorem: _model(LoremUnit.paragraphs, 5, startWithLorem: false),
        ),
      ],
    );

    blocTest<LoremBloc, LoremState>(
      'does not generate a text just because an option changed',
      build: () => LoremBloc(_FakeLoremRepository()),
      act: (bloc) => bloc.add(const LoremCountChanged(8)),
      expect: () => const [LoremState(count: 8)],
    );

    blocTest<LoremBloc, LoremState>(
      'ignores option changes that do not change anything',
      build: () => LoremBloc(_FakeLoremRepository()),
      act: (bloc) => bloc
        ..add(const LoremUnitChanged(LoremUnit.paragraphs))
        ..add(const LoremCountChanged(3))
        ..add(const LoremOpeningToggled(true)),
      expect: () => const <LoremState>[],
    );

    blocTest<LoremBloc, LoremState>(
      'clearing drops the text but keeps the options',
      build: () => LoremBloc(_FakeLoremRepository()),
      act: (bloc) => bloc
        ..add(const LoremUnitChanged(LoremUnit.lists))
        ..add(const LoremRequested())
        ..add(const LoremCleared()),
      expect: () => [
        const LoremState(unit: LoremUnit.lists, count: 5),
        LoremState(
          unit: LoremUnit.lists,
          count: 5,
          lorem: _model(LoremUnit.lists, 5),
        ),
        const LoremState(unit: LoremUnit.lists, count: 5),
      ],
    );
  });
}
