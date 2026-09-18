import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid_generator/cpf/bloc/cpf_bloc.dart';
import 'package:uuid_generator/cpf/data/cpf_model.dart';
import 'package:uuid_generator/cpf/data/cpf_repository.dart';

class _FakeCpfRepository implements CpfRepository {
  @override
  CpfModel generate() => const CpfModel('11144477735');
}

void main() {
  group('CpfBloc', () {
    test('initial state is CpfInitial', () {
      expect(CpfBloc(_FakeCpfRepository()).state, const CpfInitial());
    });

    blocTest<CpfBloc, CpfState>(
      'emits CpfGenerated when CpfRequested is added',
      build: () => CpfBloc(_FakeCpfRepository()),
      act: (bloc) => bloc.add(const CpfRequested()),
      expect: () => const [CpfGenerated(CpfModel('11144477735'))],
    );

    blocTest<CpfBloc, CpfState>(
      'returns to CpfInitial when CpfCleared is added',
      build: () => CpfBloc(_FakeCpfRepository()),
      act: (bloc) => bloc
        ..add(const CpfRequested())
        ..add(const CpfCleared()),
      expect: () => const [
        CpfGenerated(CpfModel('11144477735')),
        CpfInitial(),
      ],
    );
  });
}
