import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/data/export_format.dart';
import '../../shared/data/list_export_repository.dart';
import '../data/cnpj_kind.dart';
import '../data/cnpj_model.dart';
import '../data/cnpj_repository.dart';

part 'cnpj_event.dart';
part 'cnpj_state.dart';

/// Mediates between the CNPJ UI, the [CnpjRepository] (generation) and the
/// [ListExportRepository] (saving the list as a file).
///
/// Like `CpfBloc`, it owns the options (amount, format, head office or
/// branch, punctuation). Changing one of the first three while CNPJs are on
/// screen regenerates them; the punctuation only changes how they are shown.
class CnpjBloc extends Bloc<CnpjEvent, CnpjState> {
  CnpjBloc(this._repository, this._exports) : super(const CnpjState()) {
    on<CnpjCountChanged>(_onCountChanged);
    on<CnpjKindChanged>(_onKindChanged);
    on<CnpjHeadOfficeToggled>(_onHeadOfficeToggled);
    on<CnpjMaskToggled>(_onMaskToggled);
    on<CnpjRequested>(_onRequested);
    on<CnpjCleared>(_onCleared);
    on<CnpjExportRequested>(_onExportRequested);
  }

  final CnpjRepository _repository;
  final ListExportRepository _exports;

  void _onCountChanged(CnpjCountChanged event, Emitter<CnpjState> emit) {
    final count = event.count.clamp(1, CnpjRepository.maxCount);
    if (count == state.count) return;
    emit(_withOptions(state.copyWith(count: count)));
  }

  void _onKindChanged(CnpjKindChanged event, Emitter<CnpjState> emit) {
    if (event.kind == state.kind) return;
    emit(_withOptions(state.copyWith(kind: event.kind)));
  }

  void _onHeadOfficeToggled(
    CnpjHeadOfficeToggled event,
    Emitter<CnpjState> emit,
  ) {
    if (event.headOffice == state.headOffice) return;
    emit(_withOptions(state.copyWith(headOffice: event.headOffice)));
  }

  void _onMaskToggled(CnpjMaskToggled event, Emitter<CnpjState> emit) {
    emit(state.copyWith(masked: event.masked));
  }

  void _onRequested(CnpjRequested event, Emitter<CnpjState> emit) {
    emit(state.copyWith(cnpjs: _generate(state)));
  }

  void _onCleared(CnpjCleared event, Emitter<CnpjState> emit) {
    emit(state.copyWith(cnpjs: const []));
  }

  /// Saves the list that is on screen when the user asks, even if it is
  /// regenerated while the dialog is open.
  Future<void> _onExportRequested(
    CnpjExportRequested event,
    Emitter<CnpjState> emit,
  ) async {
    if (!state.canExport) return;
    final values = state.values;

    emit(state.withExport(ExportStatus.saving));
    try {
      final savedTo = await _exports.save(
        fileName: 'cnpjs',
        column: 'cnpj',
        values: values,
        format: event.format,
      );
      emit(
        savedTo == null
            ? state.withExport(ExportStatus.cancelled)
            : state.withExport(ExportStatus.saved, savedTo: savedTo),
      );
    } on Exception {
      emit(state.withExport(ExportStatus.failed));
    }
  }

  /// Regenerates the CNPJs for [next] when some are already on screen.
  CnpjState _withOptions(CnpjState next) =>
      next.hasValues ? next.copyWith(cnpjs: _generate(next)) : next;

  List<CnpjModel> _generate(CnpjState from) => _repository.generateMany(
    from.count,
    kind: from.kind,
    headOffice: from.headOffice,
  );
}
