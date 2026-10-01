part of 'qr_code_bloc.dart';

/// Events accepted by [QrCodeBloc].
sealed class QrCodeEvent {
  const QrCodeEvent();
}

/// The text to encode was edited.
class QrCodeTextChanged extends QrCodeEvent {
  const QrCodeTextChanged(this.text);

  final String text;
}

/// The user picked another error correction level.
class QrCodeLevelChanged extends QrCodeEvent {
  const QrCodeLevelChanged(this.level);

  final QrCodeLevel level;
}

/// Requests a made-up content (link, Wi-Fi, e-mail...) to encode.
class QrCodeRequested extends QrCodeEvent {
  const QrCodeRequested();
}

/// Saves the code on screen as a PNG, asking the user where.
class QrCodeDownloadRequested extends QrCodeEvent {
  const QrCodeDownloadRequested();
}

/// Clears the text, keeping the level.
class QrCodeCleared extends QrCodeEvent {
  const QrCodeCleared();
}
