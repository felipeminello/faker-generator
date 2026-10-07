import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/document_validation.dart';
import '../data/validator_repository.dart';

part 'validator_event.dart';
part 'validator_state.dart';

/// Mediates between the validator UI and the [ValidatorRepository].
///
/// Like the cron editor, it checks the text as it is typed: there is no
/// separate "validate" step.
class ValidatorBloc extends Bloc<ValidatorEvent, ValidatorState> {
  ValidatorBloc(this._repository) : super(const ValidatorState()) {
    on<ValidatorTextChanged>(_onTextChanged);
    on<ValidatorExampleRequested>(_onExampleRequested);
    on<ValidatorCleared>(_onCleared);
  }

  final ValidatorRepository _repository;

  void _onTextChanged(
    ValidatorTextChanged event,
    Emitter<ValidatorState> emit,
  ) {
    if (event.text == state.text) return;
    emit(_validate(event.text));
  }

  void _onExampleRequested(
    ValidatorExampleRequested event,
    Emitter<ValidatorState> emit,
  ) {
    emit(_validate(ValidatorRepository.example));
  }

  void _onCleared(ValidatorCleared event, Emitter<ValidatorState> emit) {
    emit(const ValidatorState());
  }

  ValidatorState _validate(String text) =>
      ValidatorState(text: text, results: _repository.validateAll(text));
}
