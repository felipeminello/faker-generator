/// A class of characters the user can include in a password.
///
/// Letters and digits always contribute their whole [chars]. For [symbols],
/// [chars] is the catalog offered to the user: the characters actually used
/// are the ones picked in `PasswordOptions.symbols`.
enum PasswordCharset {
  uppercase(
    label: 'Letras maiúsculas (A-Z)',
    chars: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
  ),
  lowercase(
    label: 'Letras minúsculas (a-z)',
    chars: 'abcdefghijklmnopqrstuvwxyz',
  ),
  digits(label: 'Números (0-9)', chars: '0123456789'),

  /// Every printable ASCII punctuation character. The default selection
  /// (`PasswordOptions.defaultSymbols`) leaves out `[ ] " \`, which many sites
  /// reject; they stay available to be picked by hand.
  symbols(
    label: 'Caracteres especiais',
    chars: '`!@#\$%^&*()_+-={}|;:\',.<>/?~[]"\\',
  );

  const PasswordCharset({required this.label, required this.chars});

  /// Label shown next to the toggle.
  final String label;

  /// Characters this class draws from (the full catalog, for [symbols]).
  final String chars;
}
