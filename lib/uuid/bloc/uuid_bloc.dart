import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/uuid_model.dart';
import '../data/uuid_repository.dart';

part 'uuid_event.dart';
part 'uuid_state.dart';

/// Mediates between the UUID UI and the [UuidRepository].
class UuidBloc extends Bloc<UuidEvent, UuidState> {
  UuidBloc(this._repository) : super(const UuidInitial()) {
    on<UuidRequested>(_onRequested);
    on<UuidCleared>(_onCleared);
  }

  final UuidRepository _repository;

  void _onRequested(UuidRequested event, Emitter<UuidState> emit) {
    emit(UuidGenerated(_repository.generate()));
  }

  void _onCleared(UuidCleared event, Emitter<UuidState> emit) {
    emit(const UuidInitial());
  }
}
