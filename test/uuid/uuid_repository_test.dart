import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:uuid_generator/uuid/data/uuid_repository.dart';

void main() {
  group('UuidRepository', () {
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    test('generates a canonical v4 UUID', () {
      final uuid = UuidRepository().generate();
      expect(uuid.value, matches(pattern));
    });

    test('sets the version (4) and variant bits correctly', () {
      // The version nibble must be 4 and the variant nibble one of 8/9/a/b.
      for (var i = 0; i < 200; i++) {
        final value = UuidRepository().generate().value;
        expect(value[14], '4');
        expect('89ab', contains(value[19]));
      }
    });

    test('produces distinct values across calls', () {
      final repo = UuidRepository();
      final values = {for (var i = 0; i < 1000; i++) repo.generate().value};
      expect(values.length, 1000);
    });

    test('is deterministic with a seeded Random', () {
      final a = UuidRepository(random: Random(42)).generate();
      final b = UuidRepository(random: Random(42)).generate();
      expect(a, b);
    });
  });
}
