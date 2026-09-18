import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/cnpj_model.dart';
import '../data/cnpj_repository.dart';

part 'cnpj_event.dart';
part 'cnpj_state.dart';

/// Mediates between the CNPJ UI and the [CnpjRepository].
class CnpjBloc extends Bloc<CnpjEvent, CnpjState> {
  CnpjBloc(this._repository) : super(const CnpjInitial()) {
    on<CnpjRequested>(_onRequested);
    on<CnpjCleared>(_onCleared);
  }

  final CnpjRepository _repository;

  void _onRequested(CnpjRequested event, Emitter<CnpjState> emit) {
    emit(CnpjGenerated(_repository.generate()));
  }

  void _onCleared(CnpjCleared event, Emitter<CnpjState> emit) {
    emit(const CnpjInitial());
  }
}
