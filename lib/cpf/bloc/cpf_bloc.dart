import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/cpf_model.dart';
import '../data/cpf_repository.dart';

part 'cpf_event.dart';
part 'cpf_state.dart';

/// Mediates between the CPF UI and the [CpfRepository].
class CpfBloc extends Bloc<CpfEvent, CpfState> {
  CpfBloc(this._repository) : super(const CpfInitial()) {
    on<CpfRequested>(_onRequested);
    on<CpfCleared>(_onCleared);
  }

  final CpfRepository _repository;

  void _onRequested(CpfRequested event, Emitter<CpfState> emit) {
    emit(CpfGenerated(_repository.generate()));
  }

  void _onCleared(CpfCleared event, Emitter<CpfState> emit) {
    emit(const CpfInitial());
  }
}
