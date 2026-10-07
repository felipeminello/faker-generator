import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/cpf/bloc/cpf_bloc.dart';
import 'package:fake_generator/cpf/data/cpf_model.dart';
import 'package:fake_generator/cpf/data/cpf_repository.dart';
import 'package:fake_generator/cpf/data/uf.dart';
import 'package:fake_generator/shared/data/export_format.dart';
import 'package:fake_generator/shared/data/list_export_repository.dart';

import '../shared/fake_save_dialog.dart';

const _first = CpfModel('11144477735');
const _second = CpfModel('12345678909');

/// Hands out [_first], [_second], [_first]... and records each request.
class _FakeCpfRepository implements CpfRepository {
  final requests = <(int, Uf?)>[];

  @override
  CpfModel generate({Uf? uf}) => _first;

  @override
  List<CpfModel> generateMany(int count, {Uf? uf}) {
    requests.add((count, uf));
    return [for (var i = 0; i < count; i++) i.isEven ? _first : _second];
  }
}

void main() {
  late _FakeCpfRepository repository;
  late FakeSaveDialog dialog;

  setUp(() {
    repository = _FakeCpfRepository();
    dialog = FakeSaveDialog(Uri.file('/tmp/cpfs.csv'));
  });

  CpfBloc build() =>
      CpfBloc(repository, ListExportRepository(saveFile: dialog.call));

  group('CpfBloc', () {
    test('starts empty, one masked CPF from any unit at a time', () {
      expect(build().state, const CpfState());
      expect(build().state.values, isEmpty);
    });

    blocTest<CpfBloc, CpfState>(
      'generates as many CPFs as the amount asks for',
      build: build,
      act: (bloc) => bloc
        ..add(const CpfCountChanged(3))
        ..add(const CpfRequested()),
      expect: () => const [
        CpfState(count: 3),
        CpfState(count: 3, cpfs: [_first, _second, _first]),
      ],
      verify: (_) => expect(repository.requests, [(3, null)]),
    );

    blocTest<CpfBloc, CpfState>(
      'regenerates the CPFs on screen when the amount or the unit changes',
      build: build,
      act: (bloc) => bloc
        ..add(const CpfRequested())
        ..add(const CpfCountChanged(2))
        ..add(const CpfUfChanged(Uf.sp))
        ..add(const CpfUfChanged(null)),
      expect: () => const [
        CpfState(cpfs: [_first]),
        CpfState(count: 2, cpfs: [_first, _second]),
        CpfState(count: 2, uf: Uf.sp, cpfs: [_first, _second]),
        CpfState(count: 2, cpfs: [_first, _second]),
      ],
      verify: (_) => expect(repository.requests, [
        (1, null),
        (2, null),
        (2, Uf.sp),
        (2, null),
      ]),
    );

    blocTest<CpfBloc, CpfState>(
      'clamps the amount to 1..maxCount',
      build: build,
      act: (bloc) => bloc
        ..add(const CpfCountChanged(5000))
        ..add(const CpfCountChanged(0)),
      expect: () => const [
        CpfState(count: CpfRepository.maxCount),
        CpfState(count: 1),
      ],
    );

    blocTest<CpfBloc, CpfState>(
      'the punctuation only changes how the CPFs are shown',
      build: build,
      act: (bloc) => bloc
        ..add(const CpfRequested())
        ..add(const CpfMaskToggled(false)),
      verify: (bloc) {
        expect(bloc.state.values, ['11144477735']);
        expect(repository.requests, hasLength(1));
      },
    );

    blocTest<CpfBloc, CpfState>(
      'clearing keeps the options',
      build: build,
      seed: () => const CpfState(count: 2, uf: Uf.rj, cpfs: [_first, _second]),
      act: (bloc) => bloc.add(const CpfCleared()),
      expect: () => const [CpfState(count: 2, uf: Uf.rj)],
    );

    blocTest<CpfBloc, CpfState>(
      'exports the CPFs on screen, as shown',
      build: build,
      seed: () => const CpfState(count: 2, cpfs: [_first, _second]),
      act: (bloc) => bloc.add(const CpfExportRequested(ExportFormat.csv)),
      expect: () => [
        const CpfState(
          count: 2,
          cpfs: [_first, _second],
          export: ExportStatus.saving,
        ),
        CpfState(
          count: 2,
          cpfs: const [_first, _second],
          export: ExportStatus.saved,
          savedTo: Uri.file('/tmp/cpfs.csv'),
        ),
      ],
      verify: (_) {
        expect(dialog.saved.single.fileName, 'cpfs.csv');
        expect(dialog.saved.single.mimeType, 'text/csv');
        expect(
          dialog.saved.single.text,
          'cpf\n111.444.777-35\n123.456.789-09\n',
        );
      },
    );

    blocTest<CpfBloc, CpfState>(
      'reports a cancelled export',
      build: () {
        dialog = FakeSaveDialog();
        return build();
      },
      seed: () => const CpfState(cpfs: [_first]),
      act: (bloc) => bloc.add(const CpfExportRequested(ExportFormat.txt)),
      expect: () => const [
        CpfState(cpfs: [_first], export: ExportStatus.saving),
        CpfState(cpfs: [_first], export: ExportStatus.cancelled),
      ],
    );

    blocTest<CpfBloc, CpfState>(
      'reports a failed export',
      build: () {
        dialog = FakeSaveDialog(Exception('disk full'));
        return build();
      },
      seed: () => const CpfState(cpfs: [_first]),
      act: (bloc) => bloc.add(const CpfExportRequested(ExportFormat.json)),
      expect: () => const [
        CpfState(cpfs: [_first], export: ExportStatus.saving),
        CpfState(cpfs: [_first], export: ExportStatus.failed),
      ],
    );

    blocTest<CpfBloc, CpfState>(
      'has nothing to export before generating',
      build: build,
      act: (bloc) => bloc.add(const CpfExportRequested(ExportFormat.csv)),
      expect: () => const <CpfState>[],
      verify: (_) => expect(dialog.saved, isEmpty),
    );
  });
}
