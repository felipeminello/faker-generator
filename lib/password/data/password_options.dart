import 'password_charset.dart';

/// What a password is generated from: its length, the character classes it
/// mixes and which special characters are allowed.
///
/// Also the single source of truth for the limits, shared by the UI and the
/// Bloc (like `LoremUnit` for the Lorem Ipsum feature).
class PasswordOptions {
  const PasswordOptions({
    this.length = defaultLength,
    this.charsets = const {...PasswordCharset.values},
    this.symbols = defaultSymbols,
  });

  /// Shortest length accepted: one character of each class still fits.
  static const minLength = 4;

  static const maxLength = 64;

  static const defaultLength = 16;

  /// Special characters selected until the user picks others.
  static const defaultSymbols = '`!@#\$%^&*()_+-={}|;:\',.<>/?~';

  /// How many characters the password has.
  final int length;

  /// The character classes mixed into the password.
  final Set<PasswordCharset> charsets;

  /// The special characters allowed, in [PasswordCharset.symbols] catalog
  /// order. Only used when [charsets] includes [PasswordCharset.symbols].
  final String symbols;

  bool includes(PasswordCharset charset) => charsets.contains(charset);

  /// Clamps [length] into `[minLength, maxLength]`.
  static int clampLength(int length) => length.clamp(minLength, maxLength);

  /// The characters of each enabled class, one string per class.
  List<String> get pools => [
    for (final charset in PasswordCharset.values)
      if (includes(charset))
        charset == PasswordCharset.symbols ? symbols : charset.chars,
  ].where((pool) => pool.isNotEmpty).toList();

  /// Whether [charset] can be switched off without leaving nothing to draw
  /// from.
  bool canDisable(PasswordCharset charset) =>
      !includes(charset) || charsets.length > 1;

  /// Whether [symbol] can be deselected: the last one cannot, turn the whole
  /// class off instead.
  bool canDeselect(String symbol) =>
      !symbols.contains(symbol) || symbols.length > 1;

  /// These options with [charset] switched on or off.
  PasswordOptions withCharset(PasswordCharset charset, bool enabled) =>
      copyWith(
        charsets: {
          ...charsets.where((c) => c != charset),
          if (enabled) charset,
        },
      );

  /// These options with [symbol] selected or not, keeping catalog order so
  /// equal selections compare equal.
  PasswordOptions withSymbol(String symbol, bool selected) {
    final chosen = {...symbols.split('')};
    selected ? chosen.add(symbol) : chosen.remove(symbol);
    return copyWith(
      symbols: PasswordCharset.symbols.chars
          .split('')
          .where(chosen.contains)
          .join(),
    );
  }

  PasswordOptions copyWith({
    int? length,
    Set<PasswordCharset>? charsets,
    String? symbols,
  }) {
    return PasswordOptions(
      length: length ?? this.length,
      charsets: charsets ?? this.charsets,
      symbols: symbols ?? this.symbols,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PasswordOptions &&
          other.length == length &&
          other.charsets.length == charsets.length &&
          other.charsets.containsAll(charsets) &&
          other.symbols == symbols);

  @override
  int get hashCode =>
      Object.hash(length, Object.hashAllUnordered(charsets), symbols);

  @override
  String toString() =>
      'PasswordOptions($length, ${charsets.map((c) => c.name).join('+')}, '
      'symbols: $symbols)';
}
