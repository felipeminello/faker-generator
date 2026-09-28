part of 'password_bloc.dart';

/// State of the password feature: the generation options, the password on
/// screen and the recent passwords.
///
/// Like `LoremState`, a single class carries the options; the empty state is
/// [password] being `null`.
class PasswordState {
  const PasswordState({
    this.options = const PasswordOptions(),
    this.password,
    this.recent = const [],
    this.copied = false,
  });

  final PasswordOptions options;

  /// The password on screen, or `null` before the first generation / after
  /// clearing.
  final PasswordModel? password;

  /// The last [PasswordHistoryRepository.capacity] passwords, newest first.
  final List<PasswordModel> recent;

  /// Whether [password] was copied. A copied password is never replaced in
  /// [recent] when the options change, since it may already be in use.
  final bool copied;

  /// Whether there is a password to copy or clear.
  bool get hasPassword => password != null;

  PasswordState copyWith({
    PasswordOptions? options,
    PasswordModel? password,
    bool clearPassword = false,
    List<PasswordModel>? recent,
    bool? copied,
  }) {
    return PasswordState(
      options: options ?? this.options,
      password: clearPassword ? null : (password ?? this.password),
      recent: recent ?? this.recent,
      copied: copied ?? this.copied,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PasswordState &&
          other.options == options &&
          other.password == password &&
          listEquals(other.recent, recent) &&
          other.copied == copied);

  @override
  int get hashCode =>
      Object.hash(options, password, Object.hashAll(recent), copied);

  @override
  String toString() =>
      'PasswordState($options, password: $password, '
      'recent: ${recent.length}, copied: $copied)';
}
