import 'dart:math';

import 'password_model.dart';
import 'password_options.dart';

/// Generates random passwords with a cryptographically secure [Random].
class PasswordRepository {
  PasswordRepository({Random? random, DateTime Function()? clock})
    : _random = random ?? Random.secure(),
      _clock = clock ?? DateTime.now;

  final Random _random;
  final DateTime Function() _clock;

  /// Returns a freshly generated password for [options].
  ///
  /// Every enabled class contributes at least one character, so a password
  /// asked to have digits always has one; the rest are drawn from all the
  /// enabled classes together, and the result is shuffled so those guaranteed
  /// characters do not always open the password.
  PasswordModel generate(PasswordOptions options) {
    final pools = options.pools;
    if (pools.isEmpty) {
      throw ArgumentError.value(options, 'options', 'no characters to use');
    }

    final all = pools.join();
    final length = max(
      PasswordOptions.clampLength(options.length),
      pools.length,
    );
    final chars = [
      for (final pool in pools) _pick(pool),
      for (var i = pools.length; i < length; i++) _pick(all),
    ]..shuffle(_random);

    return PasswordModel(value: chars.join(), createdAt: _clock());
  }

  String _pick(String pool) => pool[_random.nextInt(pool.length)];
}
