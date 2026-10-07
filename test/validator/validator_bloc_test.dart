import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/validator/bloc/validator_bloc.dart';
import 'package:fake_generator/validator/data/validator_repository.dart';

void main() {
  const repository = ValidatorRepository();

  group('ValidatorBloc', () {
    test('starts empty', () {
      final state = ValidatorBloc(repository).state;

      expect(state, const ValidatorState());
      expect(state.hasText, isFalse);
      expect(state.results, isEmpty);
    });

    blocTest<ValidatorBloc, ValidatorState>(
      'validates the text as it is typed',
      build: () => ValidatorBloc(repository),
      act: (bloc) => bloc
        ..add(const ValidatorTextChanged('123.456.789-09'))
        ..add(const ValidatorTextChanged('123.456.789-09\n123'))
        ..add(const ValidatorTextChanged('123.456.789-09\n123')),
      expect: () => [
        ValidatorState(
          text: '123.456.789-09',
          results: repository.validateAll('123.456.789-09'),
        ),
        ValidatorState(
          text: '123.456.789-09\n123',
          results: repository.validateAll('123.456.789-09\n123'),
        ),
      ],
      verify: (bloc) {
        expect(bloc.state.validCount, 1);
        expect(bloc.state.invalidCount, 1);
      },
    );

    blocTest<ValidatorBloc, ValidatorState>(
      'fills in the example, then clears it',
      build: () => ValidatorBloc(repository),
      act: (bloc) => bloc
        ..add(const ValidatorExampleRequested())
        ..add(const ValidatorCleared()),
      expect: () => [
        ValidatorState(
          text: ValidatorRepository.example,
          results: repository.validateAll(ValidatorRepository.example),
        ),
        const ValidatorState(),
      ],
    );
  });
}
