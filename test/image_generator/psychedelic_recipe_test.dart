import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/image_generator/data/psychedelic_recipe.dart';

void main() {
  group('PsychedelicRecipe', () {
    test('a seed always draws the same picture', () {
      expect(
        PsychedelicRecipe.fromSeed(42).renderRgb(40, 30),
        PsychedelicRecipe.fromSeed(42).renderRgb(40, 30),
      );
    });

    test('another seed draws another picture', () {
      expect(
        PsychedelicRecipe.fromSeed(1).renderRgb(40, 30),
        isNot(PsychedelicRecipe.fromSeed(2).renderRgb(40, 30)),
      );
    });

    test('writes three bytes per pixel', () {
      expect(PsychedelicRecipe.fromSeed(7).renderRgb(5, 3), hasLength(45));
      expect(PsychedelicRecipe.fromSeed(7).renderRgb(1, 1), hasLength(3));
    });

    test('is colorful: every seed reaches far into red, green and blue', () {
      for (var seed = 0; seed < 50; seed++) {
        final pixels = PsychedelicRecipe.fromSeed(seed).renderRgb(64, 48);
        for (var channel = 0; channel < 3; channel++) {
          final values = [
            for (var i = channel; i < pixels.length; i += 3) pixels[i],
          ];
          final low = values.reduce((a, b) => a < b ? a : b);
          final high = values.reduce((a, b) => a > b ? a : b);
          expect(
            high - low,
            greaterThan(160),
            reason: 'seed $seed, channel $channel',
          );
        }
      }
    });

    test('does not depend on the resolution', () {
      // Downsampling the 4× picture by averaging each 4×4 block should land
      // close to the small one, apart from the finest stripes.
      final recipe = PsychedelicRecipe.fromSeed(3);
      final small = recipe.renderRgb(32, 24);
      final large = recipe.renderRgb(128, 96);

      var close = 0;
      for (var y = 0; y < 24; y++) {
        for (var x = 0; x < 32; x++) {
          var difference = 0;
          for (var channel = 0; channel < 3; channel++) {
            var sum = 0;
            for (var dy = 0; dy < 4; dy++) {
              for (var dx = 0; dx < 4; dx++) {
                sum += large[((y * 4 + dy) * 128 + x * 4 + dx) * 3 + channel];
              }
            }
            difference += (sum / 16 - small[(y * 32 + x) * 3 + channel])
                .abs()
                .round();
          }
          if (difference < 3 * 64) close++;
        }
      }

      expect(close / (32 * 24), greaterThan(0.75));
    });
  });
}
