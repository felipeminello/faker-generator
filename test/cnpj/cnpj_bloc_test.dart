import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/cnpj/bloc/cnpj_bloc.dart';
import 'package:fake_generator/cnpj/data/cnpj_kind.dart';
import 'package:fake_generator/cnpj/data/cnpj_model.dart';
import 'package:fake_generator/cnpj/data/cnpj_repository.dart';
import 'package:fake_generator/shared/data/export_format.dart';
import 'package:fake_generator/shared/data/list_export_repository.dart';

import '../shared/fake_save_dialog.dart';

const _numeric = CnpjModel('11222333000181');
const _alphanumeric = CnpjModel('12ABC34501DE35');

/// Hands out one CNPJ of the requested kind per request, and records each
/// request.
class _FakeCnpjRepository implements CnpjRepository {
  final requests = <(int, CnpjKind, bool)>[];

  @override
  CnpjModel generate({
    CnpjKind kind = CnpjKind.numeric,
    bool headOffice = true,
  }) => kind == CnpjKind.numeric ? _numeric : _alphanumeric;

  @override
  List<CnpjModel> generateMany(
    int count, {
    CnpjKind kind = CnpjKind.numeric,
    bool headOffice = true,
  }) {
    requests.add((count, kind, headOffice));
    return List.filled(count, generate(kind: kind, headOffice: headOffice));
  }
}

void main() {
  late _FakeCnpjRepository repository;
  late FakeSaveDialog dialog;

  setUp(() {
    repository = _FakeCnpjRepository();
    dialog = FakeSaveDialog(Uri.file('/tmp/cnpjs.json'));
  });

  CnpjBloc build() =>
      CnpjBloc(repository, ListExportRepository(saveFile: dialog.call));

  group('CnpjBloc', () {
    test('starts empty: one masked, numeric head office at a time', () {
      expect(build().state, const CnpjState());
    });

    blocTest<CnpjBloc, CnpjState>(
      'emits the generated CNPJs when CnpjRequested is added',
      build: build,
      act: (bloc) => bloc.add(const CnpjRequested()),
      expect: () => const [
        CnpjState(cnpjs: [_numeric]),
      ],
    );

    blocTest<CnpjBloc, CnpjState>(
      'regenerates the CNPJs on screen when an option changes',
      build: build,
      act: (bloc) => bloc
        ..add(const CnpjRequested())
        ..add(const CnpjKindChanged(CnpjKind.alphanumeric))
        ..add(const CnpjHeadOfficeToggled(false))
        ..add(const CnpjCountChanged(2)),
      expect: () => const [
        CnpjState(cnpjs: [_numeric]),
        CnpjState(kind: CnpjKind.alphanumeric, cnpjs: [_alphanumeric]),
        CnpjState(
          kind: CnpjKind.alphanumeric,
          headOffice: false,
          cnpjs: [_alphanumeric],
        ),
        CnpjState(
          count: 2,
          kind: CnpjKind.alphanumeric,
          headOffice: false,
          cnpjs: [_alphanumeric, _alphanumeric],
        ),
      ],
      verify: (_) => expect(repository.requests, [
        (1, CnpjKind.numeric, true),
        (1, CnpjKind.alphanumeric, true),
        (1, CnpjKind.alphanumeric, false),
        (2, CnpjKind.alphanumeric, false),
      ]),
    );

    blocTest<CnpjBloc, CnpjState>(
      'changing options before generating does not generate',
      build: build,
      act: (bloc) => bloc
        ..add(const CnpjKindChanged(CnpjKind.alphanumeric))
        ..add(const CnpjCountChanged(5000)),
      expect: () => const [
        CnpjState(kind: CnpjKind.alphanumeric),
        CnpjState(kind: CnpjKind.alphanumeric, count: CnpjRepository.maxCount),
      ],
      verify: (_) => expect(repository.requests, isEmpty),
    );

    blocTest<CnpjBloc, CnpjState>(
      'the punctuation only changes how the CNPJs are shown',
      build: build,
      seed: () => const CnpjState(cnpjs: [_alphanumeric]),
      act: (bloc) => bloc.add(const CnpjMaskToggled(false)),
      verify: (bloc) {
        expect(bloc.state.values, ['12ABC34501DE35']);
        expect(repository.requests, isEmpty);
      },
    );

    blocTest<CnpjBloc, CnpjState>(
      'returns to the empty state when CnpjCleared is added',
      build: build,
      seed: () => const CnpjState(cnpjs: [_numeric]),
      act: (bloc) => bloc.add(const CnpjCleared()),
      expect: () => const [CnpjState()],
    );

    blocTest<CnpjBloc, CnpjState>(
      'exports the CNPJs on screen as a JSON array',
      build: build,
      seed: () => const CnpjState(cnpjs: [_numeric, _alphanumeric]),
      act: (bloc) => bloc.add(const CnpjExportRequested(ExportFormat.json)),
      expect: () => [
        const CnpjState(
          cnpjs: [_numeric, _alphanumeric],
          export: ExportStatus.saving,
        ),
        CnpjState(
          cnpjs: const [_numeric, _alphanumeric],
          export: ExportStatus.saved,
          savedTo: Uri.file('/tmp/cnpjs.json'),
        ),
      ],
      verify: (_) {
        expect(dialog.saved.single.fileName, 'cnpjs.json');
        expect(dialog.saved.single.mimeType, 'application/json');
        expect(
          dialog.saved.single.text,
          '[\n  "11.222.333/0001-81",\n  "12.ABC.345/01DE-35"\n]\n',
        );
      },
    );
  });
}
