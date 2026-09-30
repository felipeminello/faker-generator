import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/qr_code_level.dart';
import '../data/qr_code_model.dart';
import '../data/qr_code_repository.dart';

part 'qr_code_event.dart';
part 'qr_code_state.dart';

/// Mediates between the QR Code UI and the [QrCodeRepository].
///
/// The code follows the text as it is typed, like the cron editor follows
/// its expression: there is no separate "encode" step.
class QrCodeBloc extends Bloc<QrCodeEvent, QrCodeState> {
  QrCodeBloc(this._repository) : super(const QrCodeState()) {
    on<QrCodeTextChanged>(_onTextChanged);
    on<QrCodeLevelChanged>(_onLevelChanged);
    on<QrCodeRequested>(_onRequested);
    on<QrCodeCleared>(_onCleared);
  }

  final QrCodeRepository _repository;

  void _onTextChanged(QrCodeTextChanged event, Emitter<QrCodeState> emit) {
    if (event.text == state.text) return;
    emit(_encode(event.text, state.level));
  }

  void _onLevelChanged(QrCodeLevelChanged event, Emitter<QrCodeState> emit) {
    if (event.level == state.level) return;
    emit(_encode(state.text, event.level));
  }

  void _onRequested(QrCodeRequested event, Emitter<QrCodeState> emit) {
    emit(_encode(_repository.random(), state.level));
  }

  void _onCleared(QrCodeCleared event, Emitter<QrCodeState> emit) {
    emit(QrCodeState(level: state.level));
  }

  QrCodeState _encode(String text, QrCodeLevel level) {
    if (text.isEmpty) return QrCodeState(level: level);
    try {
      return QrCodeState(
        text: text,
        level: level,
        qrCode: _repository.encode(text, level),
      );
    } on QrCodeTooLongException catch (error) {
      return QrCodeState(text: text, level: level, error: error);
    }
  }
}
