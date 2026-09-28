import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/password_charset.dart';
import '../data/password_history_repository.dart';
import '../data/password_model.dart';
import '../data/password_options.dart';
import '../data/password_repository.dart';

part 'password_event.dart';
part 'password_state.dart';

/// Mediates between the password UI, the [PasswordRepository] that generates
/// passwords and the [PasswordHistoryRepository] that remembers them.
///
/// Like the Lorem Ipsum Bloc, changing an option while a password is on
/// screen regenerates it, so the password always matches the options shown.
class PasswordBloc extends Bloc<PasswordEvent, PasswordState> {
  PasswordBloc(this._repository, this._history) : super(const PasswordState()) {
    on<PasswordHistoryRequested>(_onHistoryRequested);
    on<PasswordLengthChanged>(_onLengthChanged);
    on<PasswordCharsetToggled>(_onCharsetToggled);
    on<PasswordSymbolToggled>(_onSymbolToggled);
    on<PasswordSymbolsReset>(_onSymbolsReset);
    on<PasswordRequested>(_onRequested);
    on<PasswordCopied>(_onCopied);
    on<PasswordCleared>(_onCleared);
    on<PasswordHistoryCleared>(_onHistoryCleared);
  }

  final PasswordRepository _repository;
  final PasswordHistoryRepository _history;

  /// Whether the saved history has been read. Until then nothing is saved,
  /// so a password generated while it loads cannot overwrite it — and if it
  /// cannot be read, the stored history is left alone for this session.
  bool _historyLoaded = false;

  Future<void> _onHistoryRequested(
    PasswordHistoryRequested event,
    Emitter<PasswordState> emit,
  ) async {
    final List<PasswordModel> stored;
    try {
      stored = await _history.load();
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      return;
    }
    _historyLoaded = true;

    // Passwords generated while loading are newer than the stored ones.
    final generatedMeanwhile = state.recent;
    if (stored.isNotEmpty) {
      emit(state.copyWith(recent: _newest([...generatedMeanwhile, ...stored])));
    }
    if (generatedMeanwhile.isNotEmpty) await _save();
  }

  Future<void> _onLengthChanged(
    PasswordLengthChanged event,
    Emitter<PasswordState> emit,
  ) {
    final length = PasswordOptions.clampLength(event.length);
    return _applyOptions(state.options.copyWith(length: length), emit);
  }

  Future<void> _onCharsetToggled(
    PasswordCharsetToggled event,
    Emitter<PasswordState> emit,
  ) async {
    if (!event.enabled && !state.options.canDisable(event.charset)) return;
    await _applyOptions(
      state.options.withCharset(event.charset, event.enabled),
      emit,
    );
  }

  Future<void> _onSymbolToggled(
    PasswordSymbolToggled event,
    Emitter<PasswordState> emit,
  ) async {
    if (!event.selected && !state.options.canDeselect(event.symbol)) return;
    await _applyOptions(
      state.options.withSymbol(event.symbol, event.selected),
      emit,
    );
  }

  Future<void> _onSymbolsReset(
    PasswordSymbolsReset event,
    Emitter<PasswordState> emit,
  ) {
    return _applyOptions(
      state.options.copyWith(symbols: PasswordOptions.defaultSymbols),
      emit,
    );
  }

  Future<void> _onRequested(
    PasswordRequested event,
    Emitter<PasswordState> emit,
  ) async {
    final password = _repository.generate(state.options);
    emit(
      state.copyWith(
        password: password,
        copied: false,
        recent: _newest([password, ...state.recent]),
      ),
    );
    await _save();
  }

  void _onCopied(PasswordCopied event, Emitter<PasswordState> emit) {
    if (state.hasPassword) emit(state.copyWith(copied: true));
  }

  void _onCleared(PasswordCleared event, Emitter<PasswordState> emit) {
    emit(state.copyWith(clearPassword: true, copied: false));
  }

  Future<void> _onHistoryCleared(
    PasswordHistoryCleared event,
    Emitter<PasswordState> emit,
  ) async {
    emit(state.copyWith(recent: const []));
    await _save();
  }

  /// Switches to [options], regenerating the password on screen (if any).
  Future<void> _applyOptions(
    PasswordOptions options,
    Emitter<PasswordState> emit,
  ) async {
    if (options == state.options) return;

    final current = state.password;
    if (current == null) {
      emit(state.copyWith(options: options));
      return;
    }

    // While the user tunes the options, each new password takes the place of
    // the one it supersedes instead of stacking one entry per step: dragging
    // the length slider alone would flush the whole history. A copied
    // password may already be in use, so that one is kept.
    final supersedes = !state.copied && state.recent.firstOrNull == current;
    final password = _repository.generate(options);
    emit(
      state.copyWith(
        options: options,
        password: password,
        copied: false,
        recent: _newest([
          password,
          ...supersedes ? state.recent.skip(1) : state.recent,
        ]),
      ),
    );
    await _save();
  }

  List<PasswordModel> _newest(List<PasswordModel> passwords) =>
      passwords.take(PasswordHistoryRepository.capacity).toList();

  Future<void> _save() async {
    if (!_historyLoaded) return;
    try {
      await _history.save(state.recent);
    } catch (error, stackTrace) {
      addError(error, stackTrace);
    }
  }
}
