import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/data/export_format.dart';
import '../../shared/data/list_export_repository.dart';
import '../data/cpf_model.dart';
import '../data/cpf_repository.dart';
import '../data/uf.dart';

part 'cpf_event.dart';
part 'cpf_state.dart';

/// Mediates between the CPF UI, the [CpfRepository] (generation) and the
/// [ListExportRepository] (saving the list as a file).
///
/// Like `LoremBloc`, it owns the options (amount, unit of the federation and
/// punctuation). Changing the amount or the unit while CPFs are on screen
/// regenerates them; the punctuation only changes how they are shown.
class CpfBloc extends Bloc<CpfEvent, CpfState> {
  CpfBloc(this._repository, this._exports) : super(const CpfState()) {
    on<CpfCountChanged>(_onCountChanged);
    on<CpfUfChanged>(_onUfChanged);
    on<CpfMaskToggled>(_onMaskToggled);
    on<CpfRequested>(_onRequested);
    on<CpfCleared>(_onCleared);
    on<CpfExportRequested>(_onExportRequested);
  }

  final CpfRepository _repository;
  final ListExportRepository _exports;

  void _onCountChanged(CpfCountChanged event, Emitter<CpfState> emit) {
    final count = event.count.clamp(1, CpfRepository.maxCount);
    if (count == state.count) return;
    emit(_withOptions(state.copyWith(count: count)));
  }

  void _onUfChanged(CpfUfChanged event, Emitter<CpfState> emit) {
    if (event.uf == state.uf) return;
    emit(_withOptions(state.copyWith(uf: event.uf, anyUf: event.uf == null)));
  }

  void _onMaskToggled(CpfMaskToggled event, Emitter<CpfState> emit) {
    emit(state.copyWith(masked: event.masked));
  }

  void _onRequested(CpfRequested event, Emitter<CpfState> emit) {
    emit(state.copyWith(cpfs: _generate(state)));
  }

  void _onCleared(CpfCleared event, Emitter<CpfState> emit) {
    emit(state.copyWith(cpfs: const []));
  }

  /// Saves the list that is on screen when the user asks, even if it is
  /// regenerated while the dialog is open.
  Future<void> _onExportRequested(
    CpfExportRequested event,
    Emitter<CpfState> emit,
  ) async {
    if (!state.canExport) return;
    final values = state.values;

    emit(state.withExport(ExportStatus.saving));
    try {
      final savedTo = await _exports.save(
        fileName: 'cpfs',
        column: 'cpf',
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

  /// Regenerates the CPFs for [next] when some are already on screen.
  CpfState _withOptions(CpfState next) =>
      next.hasValues ? next.copyWith(cpfs: _generate(next)) : next;

  List<CpfModel> _generate(CpfState from) =>
      _repository.generateMany(from.count, uf: from.uf);
}
