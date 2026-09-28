import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'password_model.dart';

/// Keeps the most recent passwords across app restarts.
///
/// They are stored as JSON in the platform's app preferences (plain text,
/// inside the app's own storage), newest first.
class PasswordHistoryRepository {
  PasswordHistoryRepository({this._preferences});

  /// How many passwords are kept.
  static const capacity = 10;

  static const _key = 'password_history';

  // Created on first use: the constructor throws until the plugin has
  // registered, which never happens in widget tests that don't use it.
  SharedPreferencesAsync? _preferences;
  SharedPreferencesAsync get _store =>
      _preferences ??= SharedPreferencesAsync();

  /// The saved passwords, newest first. An unreadable history (corrupted, or
  /// written by an incompatible version) is treated as empty.
  Future<List<PasswordModel>> load() async {
    final raw = await _store.getString(_key);
    if (raw == null) return const [];

    try {
      return [
        for (final entry in jsonDecode(raw) as List<Object?>)
          PasswordModel.fromJson(entry! as Map<String, Object?>),
      ].take(capacity).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Replaces the saved history with [passwords] (newest first), keeping at
  /// most [capacity] of them.
  Future<void> save(List<PasswordModel> passwords) {
    if (passwords.isEmpty) return _store.remove(_key);
    return _store.setString(
      _key,
      jsonEncode([for (final p in passwords.take(capacity)) p.toJson()]),
    );
  }
}
