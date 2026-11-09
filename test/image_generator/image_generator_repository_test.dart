import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/image_generator/data/generated_image_model.dart';
import 'package:fake_generator/image_generator/data/image_generator_repository.dart';

import '../shared/png_decoder.dart';

void main() {
  group('ImageGeneratorRepository', () {
    test('generates an image of the given size with a random seed', () {
      final repository = ImageGeneratorRepository(random: Random(1));
      final first = repository.generate(1024, 768);
      final second = repository.generate(1024, 768);

      expect([first.width, first.height], [1024, 768]);
      expect(first.seed, isNot(second.seed));
    });

    test('names the file after the size', () {
      const image = GeneratedImageModel(width: 1920, height: 1080, seed: 1);

      expect(image.fileName, 'imagem-1920x1080.png');
    });

    test('renders the PNG at full size, in RGB', () {
      final png = decodePng(
        ImageGeneratorRepository.renderPng(
          const GeneratedImageModel(width: 70, height: 30, seed: 5),
        ),
      );

      expect([png.width, png.height, png.channels], [70, 30, 3]);
    });

    group('preview', () {
      final repository = ImageGeneratorRepository();

      ({int width, int height}) previewSize(int width, int height) {
        final png = decodePng(
          repository.preview(
            GeneratedImageModel(width: width, height: height, seed: 9),
          ),
        );
        return (width: png.width, height: png.height);
      }

      test('scales a large image down, keeping its proportions', () {
        expect(previewSize(1024, 768), (width: 480, height: 360));
        expect(previewSize(1080, 1920), (width: 270, height: 480));
      });

      test('keeps a small image at its size', () {
        expect(previewSize(100, 50), (width: 100, height: 50));
      });

      test('never makes a side thinner than one pixel', () {
        expect(previewSize(4096, 1), (width: 480, height: 1));
      });

      test('is the picture the full size shows', () {
        const image = GeneratedImageModel(width: 480, height: 360, seed: 9);

        expect(
          repository.preview(image),
          ImageGeneratorRepository.renderPng(image),
        );
      });
    });
  });
}
