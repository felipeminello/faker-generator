part of 'password_bloc.dart';

/// Events accepted by [PasswordBloc].
sealed class PasswordEvent {
  const PasswordEvent();
}

/// Loads the saved recent passwords. Added once, when the Bloc is created.
class PasswordHistoryRequested extends PasswordEvent {
  const PasswordHistoryRequested();
}

/// The user picked another length. Values outside the range are clamped.
class PasswordLengthChanged extends PasswordEvent {
  const PasswordLengthChanged(this.length);

  final int length;
}

/// The user switched a character class on or off.
class PasswordCharsetToggled extends PasswordEvent {
  const PasswordCharsetToggled(this.charset, this.enabled);

  final PasswordCharset charset;
  final bool enabled;
}

/// The user selected or deselected one special character.
class PasswordSymbolToggled extends PasswordEvent {
  const PasswordSymbolToggled(this.symbol, this.selected);

  final String symbol;
  final bool selected;
}

/// Restores the default special characters.
class PasswordSymbolsReset extends PasswordEvent {
  const PasswordSymbolsReset();
}

/// Requests a new password using the current options.
class PasswordRequested extends PasswordEvent {
  const PasswordRequested();
}

/// The password on screen was copied to the clipboard.
class PasswordCopied extends PasswordEvent {
  const PasswordCopied();
}

/// Clears the password on screen, keeping the options and the history.
class PasswordCleared extends PasswordEvent {
  const PasswordCleared();
}

/// Forgets every recent password.
class PasswordHistoryCleared extends PasswordEvent {
  const PasswordHistoryCleared();
}
