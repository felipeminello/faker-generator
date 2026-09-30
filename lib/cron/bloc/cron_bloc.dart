import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/cron_field.dart';
import '../data/cron_model.dart';
import '../data/cron_repository.dart';
import '../data/cron_schedule.dart';

part 'cron_event.dart';
part 'cron_state.dart';

/// Mediates between the cron editor UI and the [CronRepository].
///
/// Every change to the expression is explained right away, the way
/// crontab.guru does: a valid one gets its description and next runs, an
/// invalid one the reason (and the field) it fails on.
class CronBloc extends Bloc<CronEvent, CronState> {
  CronBloc(this._repository) : super(const CronState()) {
    on<CronExpressionChanged>(_onExpressionChanged);
    on<CronCursorMoved>(_onCursorMoved);
    on<CronRequested>(_onRequested);
    on<CronCleared>(_onCleared);
    on<CronRefreshed>(_onRefreshed);
  }

  final CronRepository _repository;

  void _onExpressionChanged(
    CronExpressionChanged event,
    Emitter<CronState> emit,
  ) {
    if (event.expression == state.expression) return;
    emit(_explain(event.expression));
  }

  void _onCursorMoved(CronCursorMoved event, Emitter<CronState> emit) {
    final offset = event.offset;
    final field = offset == null
        ? null
        : _repository.fieldAt(state.expression, offset);
    if (field == state.activeField) return;
    emit(
      field == null
          ? state.withoutActiveField()
          : state.copyWith(activeField: field),
    );
  }

  void _onRequested(CronRequested event, Emitter<CronState> emit) {
    emit(_explain(_repository.random()));
  }

  void _onCleared(CronCleared event, Emitter<CronState> emit) {
    emit(_explain(''));
  }

  void _onRefreshed(CronRefreshed event, Emitter<CronState> emit) {
    if (state.cron == null) return;
    final cron = _repository.explain(state.expression);
    if (cron != state.cron) emit(state.copyWith(cron: cron));
  }

  /// The state for [expression], keeping the field under the cursor: the
  /// text field reports where the cursor went right after the change.
  CronState _explain(String expression) {
    final fieldSpans = _repository.fieldSpans(expression);
    if (expression.trim().isEmpty) {
      return CronState(
        expression: expression,
        activeField: state.activeField,
        fieldSpans: fieldSpans,
      );
    }

    try {
      return CronState(
        expression: expression,
        cron: _repository.explain(expression),
        activeField: state.activeField,
        fieldSpans: fieldSpans,
      );
    } on CronFormatException catch (error) {
      return CronState(
        expression: expression,
        error: error,
        activeField: state.activeField,
        fieldSpans: fieldSpans,
      );
    }
  }
}
