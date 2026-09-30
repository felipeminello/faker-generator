part of 'qr_code_bloc.dart';

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
  });

  /// The text as typed. Spaces count: they are part of what gets encoded.
  final String text;

  /// Error correction level used to encode [text].
  final QrCodeLevel level;

  /// The encoded code, when [text] fits.
  final QrCodeModel? qrCode;

  /// Why [text] could not be encoded, when it does not fit.
  final QrCodeTooLongException? error;

  /// Whether there is a text to copy or clear.
  bool get hasText => text.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QrCodeState &&
          other.text == text &&
          other.level == level &&
          other.qrCode == qrCode &&
          other.error == error);

  @override
  int get hashCode => Object.hash(text, level, qrCode, error);

  @override
  String toString() =>
      'QrCodeState("$text", ${level.label}, qrCode: $qrCode, error: $error)';
}
