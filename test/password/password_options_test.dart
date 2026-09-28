import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/password/data/password_charset.dart';
import 'package:fake_generator/password/data/password_options.dart';

void main() {
  group('PasswordCharset.symbols', () {
    test('offers every printable ASCII punctuation character once', () {
      final catalog = PasswordCharset.symbols.chars;
      final punctuation = [
        for (var code = 0x21; code < 0x7f; code++) String.fromCharCode(code),
      ].where((c) => !RegExp('[A-Za-z0-9]').hasMatch(c));

      expect(catalog.split('').toSet(), punctuation.toSet());
      expect(catalog, hasLength(punctuation.length));
    });
  });

  group('PasswordOptions', () {
    test('defaults to 16 characters with every class enabled', () {
      const options = PasswordOptions();

      expect(options.length, 16);
      expect(options.charsets, PasswordCharset.values.toSet());
      expect(options.symbols, PasswordOptions.defaultSymbols);
    });

    test('selects the requested special characters by default', () {
      expect(
        PasswordOptions.defaultSymbols.split('').toSet(),
        "` ! @ # \$ % ^ & * ( ) _ + - = { } | ; : ' , . < > / ? ~"
            .split(' ')
            .toSet(),
      );
      expect(PasswordOptions.defaultSymbols, hasLength(28));
    });

    test('only the last enabled class cannot be disabled', () {
      const all = PasswordOptions();
      const digitsOnly = PasswordOptions(charsets: {PasswordCharset.digits});

      expect(PasswordCharset.values.every(all.canDisable), isTrue);
      expect(digitsOnly.canDisable(PasswordCharset.digits), isFalse);
      expect(digitsOnly.canDisable(PasswordCharset.uppercase), isTrue);
    });

    test('only the last selected symbol cannot be deselected', () {
      const one = PasswordOptions(symbols: '#');

      expect(one.canDeselect('#'), isFalse);
      expect(one.canDeselect('!'), isTrue);
      expect(const PasswordOptions().canDeselect('#'), isTrue);
    });

    test('keeps the selected symbols in catalog order, without repeats', () {
      const options = PasswordOptions(symbols: '#');

      expect(options.withSymbol('!', true).symbols, '!#');
      expect(options.withSymbol('#', true).symbols, '#');
      expect(options.withSymbol('!', true).withSymbol('#', false).symbols, '!');
    });

    test('compares charsets regardless of the order they were enabled', () {
      const a = PasswordOptions(
        charsets: {PasswordCharset.digits, PasswordCharset.lowercase},
      );
      const b = PasswordOptions(
        charsets: {PasswordCharset.lowercase, PasswordCharset.digits},
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a.withCharset(PasswordCharset.digits, false),
        const PasswordOptions(charsets: {PasswordCharset.lowercase}),
      );
    });
  });
}
