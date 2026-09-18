import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/cnpj/bloc/cnpj_bloc.dart';
import 'package:fake_generator/cnpj/data/cnpj_model.dart';
import 'package:fake_generator/cnpj/data/cnpj_repository.dart';

class _FakeCnpjRepository implements CnpjRepository {
  @override
  CnpjModel generate() => const CnpjModel('11222333000181');
}

void main() {
  group('CnpjBloc', () {
    test('initial state is CnpjInitial', () {
      expect(CnpjBloc(_FakeCnpjRepository()).state, const CnpjInitial());
    });

    blocTest<CnpjBloc, CnpjState>(
      'emits CnpjGenerated when CnpjRequested is added',
      build: () => CnpjBloc(_FakeCnpjRepository()),
      act: (bloc) => bloc.add(const CnpjRequested()),
      expect: () => const [CnpjGenerated(CnpjModel('11222333000181'))],
    );

    blocTest<CnpjBloc, CnpjState>(
      'returns to CnpjInitial when CnpjCleared is added',
      build: () => CnpjBloc(_FakeCnpjRepository()),
      act: (bloc) => bloc
        ..add(const CnpjRequested())
        ..add(const CnpjCleared()),
      expect: () => const [
        CnpjGenerated(CnpjModel('11222333000181')),
        CnpjInitial(),
      ],
    );
  });
}
