import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/lorem_model.dart';
import '../data/lorem_repository.dart';
import '../data/lorem_unit.dart';

part 'lorem_event.dart';
part 'lorem_state.dart';

/// Mediates between the Lorem Ipsum UI and the [LoremRepository].
///
/// The Bloc owns the generation options (unit, amount and whether the text
/// starts with the classic "Lorem ipsum..." opening). Changing an option while
/// a text is on screen regenerates it, so the result always matches the
/// options being shown.
class LoremBloc extends Bloc<LoremEvent, LoremState> {
  LoremBloc(this._repository) : super(const LoremState()) {
    on<LoremUnitChanged>(_onUnitChanged);
    on<LoremCountChanged>(_onCountChanged);
    on<LoremOpeningToggled>(_onOpeningToggled);
    on<LoremRequested>(_onRequested);
    on<LoremCleared>(_onCleared);
  }

  final LoremRepository _repository;

  /// Switching the unit also resets the amount, since each unit has its own
  /// range (3 paragraphs and 3 letters are not comparable requests).
  void _onUnitChanged(LoremUnitChanged event, Emitter<LoremState> emit) {
    if (event.unit == state.unit) return;
    emit(
      _withOptions(
        state.copyWith(unit: event.unit, count: event.unit.defaultCount),
      ),
    );
  }

  void _onCountChanged(LoremCountChanged event, Emitter<LoremState> emit) {
    final count = state.unit.clampCount(event.count);
    if (count == state.count) return;
    emit(_withOptions(state.copyWith(count: count)));
  }

  void _onOpeningToggled(LoremOpeningToggled event, Emitter<LoremState> emit) {
    if (event.startWithLorem == state.startWithLorem) return;
    emit(_withOptions(state.copyWith(startWithLorem: event.startWithLorem)));
  }

  void _onRequested(LoremRequested event, Emitter<LoremState> emit) {
    emit(state.copyWith(lorem: _generate(state)));
  }

  void _onCleared(LoremCleared event, Emitter<LoremState> emit) {
    emit(state.copyWith(clearLorem: true));
  }

  /// Regenerates the text for [next] when one is already on screen.
  LoremState _withOptions(LoremState next) =>
      next.lorem == null ? next : next.copyWith(lorem: _generate(next));

  LoremModel _generate(LoremState from) => _repository.generate(
    unit: from.unit,
    count: from.count,
    startWithLorem: from.startWithLorem,
  );
}
