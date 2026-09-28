import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/password/data/password_charset.dart';
import 'package:fake_generator/password/data/password_options.dart';
import 'package:fake_generator/password/data/password_repository.dart';

void main() {
  group('PasswordRepository', () {
    test('generates a password of the requested length', () {
      for (final length in [4, 16, 37, 64]) {
        final password = PasswordRepository().generate(
          PasswordOptions(length: length),
        );
        expect(password.value, hasLength(length), reason: 'for $length');
      }
    });

    test('defaults to 16 characters', () {
      expect(
        PasswordRepository().generate(const PasswordOptions()).value,
        hasLength(16),
      );
    });

    test('uses only the enabled character classes', () {
      final repo = PasswordRepository();

      expect(
        repo
            .generate(
              const PasswordOptions(
                length: 64,
                charsets: {PasswordCharset.digits},
              ),
            )
            .value,
        matches(RegExp(r'^[0-9]+$')),
      );
      expect(
        repo
            .generate(
              const PasswordOptions(
                length: 64,
                charsets: {
                  PasswordCharset.uppercase,
                  PasswordCharset.lowercase,
                },
              ),
            )
            .value,
        matches(RegExp(r'^[A-Za-z]+$')),
      );
    });

    test('draws special characters only from the chosen ones', () {
      final password = PasswordRepository().generate(
        const PasswordOptions(
          length: 64,
          charsets: {PasswordCharset.lowercase, PasswordCharset.symbols},
          symbols: '#_',
        ),
      );

      expect(password.value, matches(RegExp(r'^[a-z#_]+$')));
    });

    test('includes at least one character of every enabled class', () {
      final repo = PasswordRepository(random: Random(1));

      // At the minimum length every character is a guaranteed one, so a
      // missing class would show up quickly.
      for (var i = 0; i < 500; i++) {
        final value = repo
            .generate(const PasswordOptions(length: PasswordOptions.minLength))
            .value;
        expect(value, contains(RegExp('[A-Z]')), reason: value);
        expect(value, contains(RegExp('[a-z]')), reason: value);
        expect(value, contains(RegExp('[0-9]')), reason: value);
        expect(value, contains(RegExp(r'[^A-Za-z0-9]')), reason: value);
      }
    });

    test('shuffles the guaranteed characters', () {
      final repo = PasswordRepository(random: Random(2));
      final firsts = {
        for (var i = 0; i < 200; i++)
          repo.generate(const PasswordOptions(length: 4)).value[0],
      };

      // Without the shuffle the password would always open with a capital.
      expect(firsts.any((c) => !RegExp('[A-Z]').hasMatch(c)), isTrue);
    });

    test('clamps the length to the accepted range', () {
      final repo = PasswordRepository();

      expect(
        repo.generate(const PasswordOptions(length: 1)).value,
        hasLength(PasswordOptions.minLength),
      );
      expect(
        repo.generate(const PasswordOptions(length: 999)).value,
        hasLength(PasswordOptions.maxLength),
      );
    });

    test('refuses options with no characters to use', () {
      expect(
        () => PasswordRepository().generate(
          const PasswordOptions(
            charsets: {PasswordCharset.symbols},
            symbols: '',
          ),
        ),
        throwsArgumentError,
      );
    });

    test('is deterministic with a seeded Random', () {
      final clock = DateTime(2026, 9, 27);
      final a = PasswordRepository(
        random: Random(7),
        clock: () => clock,
      ).generate(const PasswordOptions());
      final b = PasswordRepository(
        random: Random(7),
        clock: () => clock,
      ).generate(const PasswordOptions());

      expect(a, b);
    });

    test('stamps the password with the time it was generated', () {
      final now = DateTime(2026, 9, 27, 14, 5);
      final password = PasswordRepository(
        clock: () => now,
      ).generate(const PasswordOptions());

      expect(password.createdAt, now);
    });
  });
}
