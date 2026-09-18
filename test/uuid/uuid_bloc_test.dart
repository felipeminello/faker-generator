import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/uuid/bloc/uuid_bloc.dart';
import 'package:fake_generator/uuid/data/uuid_model.dart';
import 'package:fake_generator/uuid/data/uuid_repository.dart';

class _FakeUuidRepository implements UuidRepository {
  var _counter = 0;

  @override
  UuidModel generate() => UuidModel('uuid-${_counter++}');
}

void main() {
  group('UuidBloc', () {
    test('initial state is UuidInitial', () {
      expect(UuidBloc(_FakeUuidRepository()).state, const UuidInitial());
    });

    blocTest<UuidBloc, UuidState>(
      'emits UuidGenerated when UuidRequested is added',
      build: () => UuidBloc(_FakeUuidRepository()),
      act: (bloc) => bloc.add(const UuidRequested()),
      expect: () => const [UuidGenerated(UuidModel('uuid-0'))],
    );

    blocTest<UuidBloc, UuidState>(
      'returns to UuidInitial when UuidCleared is added',
      build: () => UuidBloc(_FakeUuidRepository()),
      act: (bloc) => bloc
        ..add(const UuidRequested())
        ..add(const UuidCleared()),
      expect: () => const [
        UuidGenerated(UuidModel('uuid-0')),
        UuidInitial(),
      ],
    );
  });
}
