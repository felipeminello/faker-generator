import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/lorem/data/lorem_repository.dart';
import 'package:fake_generator/lorem/data/lorem_unit.dart';

/// Counts whitespace-separated tokens that contain at least one letter.
int wordsIn(String text) => text
    .split(RegExp(r'\s+'))
    .where((token) => RegExp('[A-Za-z]').hasMatch(token))
    .length;

void main() {
  group('LoremRepository', () {
    test('generates the requested number of paragraphs', () {
      final lorem = LoremRepository().generate(
        unit: LoremUnit.paragraphs,
        count: 4,
      );

      expect(lorem.text.split('\n\n'), hasLength(4));
      expect(lorem.count, 4);
      expect(lorem.unit, LoremUnit.paragraphs);
    });

    test('generates exactly the requested number of words', () {
      for (final count in [1, 7, 50, 137]) {
        final lorem = LoremRepository().generate(
          unit: LoremUnit.words,
          count: count,
        );
        expect(wordsIn(lorem.text), count, reason: 'for $count words');
      }
    });

    test('generates exactly the requested number of letters', () {
      for (final count in [1, 12, 250, 1013]) {
        final lorem = LoremRepository().generate(
          unit: LoremUnit.letters,
          count: count,
        );
        expect(lorem.text, hasLength(count));
        expect(lorem.text.endsWith(' '), isFalse);
      }
    });

    test('generates one bulleted item per requested list', () {
      final lorem = LoremRepository().generate(unit: LoremUnit.lists, count: 6);

      final lines = lorem.text.split('\n');
      expect(lines, hasLength(6));
      expect(lines.every((line) => line.startsWith('• ')), isTrue);
    });

    test('starts with the classic opening when asked to', () {
      final lorem = LoremRepository().generate(
        unit: LoremUnit.paragraphs,
        count: 2,
      );

      expect(lorem.text, startsWith(LoremRepository.openingSentence));
    });

    test('skips the classic opening when startWithLorem is false', () {
      // Random text may still open with "Lorem" by chance, so check the whole
      // canonical sentence instead of the first word.
      final lorem = LoremRepository().generate(
        unit: LoremUnit.paragraphs,
        count: 2,
        startWithLorem: false,
      );

      expect(lorem.text.startsWith(LoremRepository.openingSentence), isFalse);
    });

    test('clamps the amount to the range of the unit', () {
      final repo = LoremRepository();

      expect(repo.generate(unit: LoremUnit.words, count: 0).count, 1);
      expect(
        repo.generate(unit: LoremUnit.paragraphs, count: 999).count,
        LoremUnit.paragraphs.max,
      );
    });

    test('ends paragraphs, words and lists with readable punctuation', () {
      final repo = LoremRepository();

      expect(
        repo.generate(unit: LoremUnit.paragraphs, count: 1).text,
        endsWith('.'),
      );
      expect(
        repo.generate(unit: LoremUnit.words, count: 20).text,
        endsWith('.'),
      );
      expect(
        repo.generate(unit: LoremUnit.words, count: 5).text,
        isNot(contains(',.')),
      );
    });

    test('is deterministic with a seeded Random', () {
      final a = LoremRepository(
        random: Random(7),
      ).generate(unit: LoremUnit.paragraphs, count: 3);
      final b = LoremRepository(
        random: Random(7),
      ).generate(unit: LoremUnit.paragraphs, count: 3);

      expect(a, b);
    });

    test('exposes word and character counts', () {
      final lorem = LoremRepository().generate(
        unit: LoremUnit.words,
        count: 30,
      );

      expect(lorem.wordCount, 30);
      expect(lorem.characterCount, lorem.text.length);
    });
  });
}
