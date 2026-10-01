part of 'qr_code_bloc.dart';

/// Where saving the code as a PNG stands. The page shows a message when it
/// leaves [saving].
enum QrCodeDownloadStatus { idle, saving, saved, cancelled, failed }

/// State of the QR Code generator: the text, the error correction level and
/// the code they make.
///
/// Like `CronState`, a single class carries everything. The empty state is
/// [text] being empty; otherwise exactly one of [qrCode] and [error] is set.
class QrCodeState {
  const QrCodeState({
    this.text = '',
    this.level = QrCodeLevel.medium,
    this.qrCode,
    this.error,
    this.download = QrCodeDownloadStatus.idle,
    this.savedTo,
  });

  /// The text as typed. Spaces count: they are part of what gets encoded.
  final String text;

  /// Error correction level used to encode [text].
  final QrCodeLevel level;

  /// The encoded code, when [text] fits.
  final QrCodeModel? qrCode;

  /// Why [text] could not be encoded, when it does not fit.
  final QrCodeTooLongException? error;

  /// Where the last download stands. It survives edits to the text, so a
  /// second download cannot start while the save dialog is still open.
  final QrCodeDownloadStatus download;

  /// Where the last download was saved, once it is [QrCodeDownloadStatus.saved].
  final Uri? savedTo;

  /// Whether there is a text to clear.
  bool get hasText => text.isNotEmpty;

  /// Whether there is a code to download.
  bool get canDownload =>
      qrCode != null && download != QrCodeDownloadStatus.saving;

  /// This state with the download at [status] (and saved to [savedTo]).
  QrCodeState withDownload(QrCodeDownloadStatus status, {Uri? savedTo}) =>
      QrCodeState(
        text: text,
        level: level,
        qrCode: qrCode,
        error: error,
        download: status,
        savedTo: savedTo,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QrCodeState &&
          other.text == text &&
          other.level == level &&
          other.qrCode == qrCode &&
          other.error == error &&
          other.download == download &&
          other.savedTo == savedTo);

  @override
  int get hashCode =>
      Object.hash(text, level, qrCode, error, download, savedTo);

  @override
  String toString() =>
      'QrCodeState("$text", ${level.label}, qrCode: $qrCode, error: $error, '
      'download: ${download.name})';
}
