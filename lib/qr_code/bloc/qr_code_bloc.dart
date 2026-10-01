import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/qr_code_download_repository.dart';
import '../data/qr_code_level.dart';
import '../data/qr_code_model.dart';
import '../data/qr_code_repository.dart';

part 'qr_code_event.dart';
part 'qr_code_state.dart';

/// Mediates between the QR Code UI, the [QrCodeRepository] (encoding) and the
/// [QrCodeDownloadRepository] (saving as PNG).
///
/// The code follows the text as it is typed, like the cron editor follows
/// its expression: there is no separate "encode" step.
class QrCodeBloc extends Bloc<QrCodeEvent, QrCodeState> {
  QrCodeBloc(this._repository, this._downloads) : super(const QrCodeState()) {
    on<QrCodeTextChanged>(_onTextChanged);
    on<QrCodeLevelChanged>(_onLevelChanged);
    on<QrCodeRequested>(_onRequested);
    on<QrCodeCleared>(_onCleared);
    on<QrCodeDownloadRequested>(_onDownloadRequested);
  }

  final QrCodeRepository _repository;
  final QrCodeDownloadRepository _downloads;

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
    emit(_encode('', state.level));
  }

  /// Saves the code that is on screen when the user asks, even if the text
  /// changes while the dialog is open.
  Future<void> _onDownloadRequested(
    QrCodeDownloadRequested event,
    Emitter<QrCodeState> emit,
  ) async {
    final qrCode = state.qrCode;
    if (qrCode == null || !state.canDownload) return;

    emit(state.withDownload(QrCodeDownloadStatus.saving));
    try {
      final savedTo = await _downloads.save(qrCode);
      emit(
        savedTo == null
            ? state.withDownload(QrCodeDownloadStatus.cancelled)
            : state.withDownload(QrCodeDownloadStatus.saved, savedTo: savedTo),
      );
    } on Exception {
      emit(state.withDownload(QrCodeDownloadStatus.failed));
    }
  }

  /// The state for [text] at [level], keeping where the download stands.
  QrCodeState _encode(String text, QrCodeLevel level) {
    final download = state.download;
    if (text.isEmpty) return QrCodeState(level: level, download: download);
    try {
      return QrCodeState(
        text: text,
        level: level,
        qrCode: _repository.encode(text, level),
        download: download,
      );
    } on QrCodeTooLongException catch (error) {
      return QrCodeState(
        text: text,
        level: level,
        error: error,
        download: download,
      );
    }
  }
}
