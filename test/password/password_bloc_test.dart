import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/password/bloc/password_bloc.dart';
import 'package:fake_generator/password/data/password_charset.dart';
import 'package:fake_generator/password/data/password_history_repository.dart';
import 'package:fake_generator/password/data/password_model.dart';
import 'package:fake_generator/password/data/password_options.dart';
import 'package:fake_generator/password/data/password_repository.dart';

/// Numbers the passwords it generates and writes the length into them, so
/// the tests can tell which generation (and with which length) they are.
class _FakePasswordRepository implements PasswordRepository {
  var _generated = 0;

  @override
  PasswordModel generate(PasswordOptions options) =>
      _password(++_generated, options.length);
}

/// In-memory history that records every save.
class _FakeHistory implements PasswordHistoryRepository {
  _FakeHistory({this.stored = const [], this.loading, this.loadError});

  List<PasswordModel> stored;

  /// When set, [load] waits for it instead of answering right away.
  final Completer<void>? loading;

  final Object? loadError;

  final saves = <List<PasswordModel>>[];

  @override
  Future<List<PasswordModel>> load() async {
    await loading?.future;
    if (loadError != null) throw loadError!;
    return stored;
  }

  @override
  Future<void> save(List<PasswordModel> passwords) async {
    saves.add(passwords);
    stored = passwords;
  }
}

PasswordModel _password(int n, [int length = 16]) =>
    PasswordModel(value: 'p$n/$length', createdAt: DateTime(2026, 9, 27, 0, n));

/// Adds [PasswordHistoryRequested] and lets the (fake) load finish, as the
/// app does before the user can tap anything.
Future<void> _loadHistory(PasswordBloc bloc) async {
  bloc.add(const PasswordHistoryRequested());
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('PasswordBloc', () {
    late _FakeHistory history;

    setUp(() => history = _FakeHistory());

    PasswordBloc build() => PasswordBloc(_FakePasswordRepository(), history);

    test('starts with the default options and nothing generated', () {
      final bloc = build();

      expect(bloc.state, const PasswordState());
      expect(bloc.state.options, const PasswordOptions());
      expect(bloc.state.hasPassword, isFalse);
      expect(bloc.state.recent, isEmpty);
    });

    blocTest<PasswordBloc, PasswordState>(
      'generates a password and saves it as the most recent',
      build: build,
      act: (bloc) async {
        await _loadHistory(bloc);
        bloc.add(const PasswordRequested());
      },
      expect: () => [
        PasswordState(password: _password(1), recent: [_password(1)]),
      ],
      verify: (_) => expect(history.saves, [
        [_password(1)],
      ]),
    );

    blocTest<PasswordBloc, PasswordState>(
      'each refresh adds a new entry, keeping only the 10 newest',
      build: build,
      act: (bloc) async {
        await _loadHistory(bloc);
        for (var i = 0; i < 12; i++) {
          bloc.add(const PasswordRequested());
        }
      },
      verify: (bloc) {
        expect(bloc.state.password, _password(12));
        expect(bloc.state.recent, [for (var n = 12; n > 2; n--) _password(n)]);
        expect(history.stored, bloc.state.recent);
      },
    );

    blocTest<PasswordBloc, PasswordState>(
      'loads the saved history',
      build: () {
        history = _FakeHistory(stored: [_password(8), _password(7)]);
        return build();
      },
      act: (bloc) => bloc.add(const PasswordHistoryRequested()),
      expect: () => [
        PasswordState(recent: [_password(8), _password(7)]),
      ],
      verify: (_) => expect(history.saves, isEmpty),
    );

    blocTest<PasswordBloc, PasswordState>(
      'puts passwords generated while loading before the saved ones',
      build: () {
        history = _FakeHistory(stored: [_password(9)], loading: Completer());
        return build();
      },
      act: (bloc) async {
        bloc
          ..add(const PasswordHistoryRequested())
          ..add(const PasswordRequested());
        await Future<void>.delayed(Duration.zero);
        // Nothing was saved yet: it would have overwritten the stored history.
        expect(history.saves, isEmpty);
        history.loading!.complete();
      },
      expect: () => [
        PasswordState(password: _password(1), recent: [_password(1)]),
        PasswordState(
          password: _password(1),
          recent: [_password(1), _password(9)],
        ),
      ],
      verify: (_) => expect(history.saves, [
        [_password(1), _password(9)],
      ]),
    );

    blocTest<PasswordBloc, PasswordState>(
      'leaves the saved history alone when it cannot be read',
      build: () {
        history = _FakeHistory(loadError: StateError('disk'));
        return build();
      },
      act: (bloc) async {
        await _loadHistory(bloc);
        bloc.add(const PasswordRequested());
      },
      expect: () => [
        PasswordState(password: _password(1), recent: [_password(1)]),
      ],
      errors: () => [isA<StateError>()],
      verify: (_) => expect(history.saves, isEmpty),
    );

    blocTest<PasswordBloc, PasswordState>(
      'changing an option with nothing on screen does not generate',
      build: build,
      act: (bloc) => bloc.add(const PasswordLengthChanged(20)),
      expect: () => const [PasswordState(options: PasswordOptions(length: 20))],
    );

    blocTest<PasswordBloc, PasswordState>(
      'clamps the length to the accepted range',
      build: build,
      act: (bloc) => bloc
        ..add(const PasswordLengthChanged(1))
        ..add(const PasswordLengthChanged(999)),
      expect: () => const [
        PasswordState(options: PasswordOptions(length: 4)),
        PasswordState(options: PasswordOptions(length: 64)),
      ],
    );

    blocTest<PasswordBloc, PasswordState>(
      'tuning the options regenerates the password in place in the history',
      build: build,
      act: (bloc) async {
        await _loadHistory(bloc);
        bloc
          ..add(const PasswordRequested())
          ..add(const PasswordLengthChanged(20))
          ..add(const PasswordLengthChanged(24));
      },
      expect: () => [
        PasswordState(password: _password(1), recent: [_password(1)]),
        PasswordState(
          options: const PasswordOptions(length: 20),
          password: _password(2, 20),
          recent: [_password(2, 20)],
        ),
        PasswordState(
          options: const PasswordOptions(length: 24),
          password: _password(3, 24),
          recent: [_password(3, 24)],
        ),
      ],
    );

    blocTest<PasswordBloc, PasswordState>(
      'keeps a copied password when the options change afterwards',
      build: build,
      act: (bloc) async {
        await _loadHistory(bloc);
        bloc
          ..add(const PasswordRequested())
          ..add(const PasswordCopied())
          ..add(const PasswordLengthChanged(20))
          ..add(const PasswordLengthChanged(24));
      },
      expect: () => [
        PasswordState(password: _password(1), recent: [_password(1)]),
        PasswordState(
          password: _password(1),
          recent: [_password(1)],
          copied: true,
        ),
        PasswordState(
          options: const PasswordOptions(length: 20),
          password: _password(2, 20),
          recent: [_password(2, 20), _password(1)],
        ),
        // The new password was not copied, so it is superseded in place.
        PasswordState(
          options: const PasswordOptions(length: 24),
          password: _password(3, 24),
          recent: [_password(3, 24), _password(1)],
        ),
      ],
    );

    blocTest<PasswordBloc, PasswordState>(
      'ignores option changes that do not change anything',
      build: build,
      act: (bloc) => bloc
        ..add(const PasswordLengthChanged(16))
        ..add(const PasswordCharsetToggled(PasswordCharset.digits, true))
        ..add(const PasswordSymbolToggled('#', true))
        ..add(const PasswordSymbolsReset()),
      expect: () => const <PasswordState>[],
    );

    blocTest<PasswordBloc, PasswordState>(
      'refuses to switch off the last character class',
      build: build,
      act: (bloc) => bloc
        ..add(const PasswordCharsetToggled(PasswordCharset.uppercase, false))
        ..add(const PasswordCharsetToggled(PasswordCharset.lowercase, false))
        ..add(const PasswordCharsetToggled(PasswordCharset.symbols, false))
        ..add(const PasswordCharsetToggled(PasswordCharset.digits, false)),
      verify: (bloc) =>
          expect(bloc.state.options.charsets, {PasswordCharset.digits}),
    );

    blocTest<PasswordBloc, PasswordState>(
      'refuses to deselect the last special character',
      build: build,
      seed: () => const PasswordState(options: PasswordOptions(symbols: '#')),
      act: (bloc) => bloc.add(const PasswordSymbolToggled('#', false)),
      expect: () => const <PasswordState>[],
    );

    blocTest<PasswordBloc, PasswordState>(
      'picks special characters and restores the default ones',
      build: build,
      seed: () => const PasswordState(options: PasswordOptions(symbols: '#')),
      act: (bloc) => bloc
        ..add(const PasswordSymbolToggled('!', true))
        ..add(const PasswordSymbolsReset()),
      expect: () => const [
        PasswordState(options: PasswordOptions(symbols: '!#')),
        PasswordState(),
      ],
    );

    blocTest<PasswordBloc, PasswordState>(
      'clearing drops the password but keeps the options and the history',
      build: build,
      act: (bloc) => bloc
        ..add(const PasswordLengthChanged(32))
        ..add(const PasswordRequested())
        ..add(const PasswordCopied())
        ..add(const PasswordCleared()),
      skip: 3,
      expect: () => [
        PasswordState(
          options: const PasswordOptions(length: 32),
          recent: [_password(1, 32)],
        ),
      ],
    );

    blocTest<PasswordBloc, PasswordState>(
      'clearing the history keeps the password on screen',
      build: build,
      act: (bloc) async {
        await _loadHistory(bloc);
        bloc
          ..add(const PasswordRequested())
          ..add(const PasswordHistoryCleared())
          // The password is no longer in the history, so tuning the options
          // must not remove anything from it.
          ..add(const PasswordLengthChanged(20));
      },
      expect: () => [
        PasswordState(password: _password(1), recent: [_password(1)]),
        PasswordState(password: _password(1)),
        PasswordState(
          options: const PasswordOptions(length: 20),
          password: _password(2, 20),
          recent: [_password(2, 20)],
        ),
      ],
      verify: (_) => expect(history.saves[1], isEmpty),
    );
  });
}
