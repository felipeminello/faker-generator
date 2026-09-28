import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/password/data/password_history_repository.dart';
import 'package:fake_generator/password/data/password_model.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

PasswordModel _password(int n) =>
    PasswordModel(value: 'senha-$n', createdAt: DateTime(2026, 9, 27, 10, n));

void main() {
  group('PasswordHistoryRepository', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('starts empty', () async {
      expect(await PasswordHistoryRepository().load(), isEmpty);
    });

    test('loads what was saved, in the same order', () async {
      final passwords = [_password(3), _password(2), _password(1)];

      await PasswordHistoryRepository().save(passwords);

      // A new instance, as after an app restart.
      expect(await PasswordHistoryRepository().load(), passwords);
    });

    test('keeps at most the capacity', () async {
      final passwords = [for (var i = 0; i < 15; i++) _password(i)];

      await PasswordHistoryRepository().save(passwords);

      expect(
        await PasswordHistoryRepository().load(),
        passwords.take(PasswordHistoryRepository.capacity),
      );
    });

    test('saving an empty history forgets the passwords', () async {
      final repo = PasswordHistoryRepository();
      await repo.save([_password(1)]);

      await repo.save(const []);

      expect(await repo.load(), isEmpty);
    });

    test('treats an unreadable history as empty', () async {
      for (final raw in ['not json', '{"value": 1}', '[{"value": 1}]']) {
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.withData({'password_history': raw});

        expect(await PasswordHistoryRepository().load(), isEmpty, reason: raw);
      }
    });
  });
}
