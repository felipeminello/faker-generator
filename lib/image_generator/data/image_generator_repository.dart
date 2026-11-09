import 'dart:math';
import 'dart:typed_data';

import '../../shared/data/png.dart';
import 'generated_image_model.dart';
import 'psychedelic_recipe.dart';

/// Makes up new images and renders them as PNG.
class ImageGeneratorRepository {
  ImageGeneratorRepository({Random? random})
    : _random = random ?? Random.secure();

  final Random _random;

  /// Longer side of the preview, in pixels: enough for the page at any
  /// window size, and quick enough to redraw while the size is typed.
  static const previewMaxSide = 480;

  /// A new image of [width]×[height] with a random seed.
  GeneratedImageModel generate(int width, int height) => GeneratedImageModel(
    width: width,
    height: height,
    seed: _random.nextInt(1 << 32),
  );

  /// [image] scaled down so its longer side is at most [maxSide], as a PNG
  /// with the same proportions. Small images are rendered at full size.
  Uint8List preview(GeneratedImageModel image, {int maxSide = previewMaxSide}) {
    final scale = min(1.0, maxSide / max(image.width, image.height));
    return renderPng(
      image.resized(
        max(1, (image.width * scale).round()),
        max(1, (image.height * scale).round()),
      ),
    );
  }

  /// [image] as a PNG at its full size.
  ///
  /// Static and free of state so it can run in another isolate: a 4096×4096
  /// image takes seconds.
  static Uint8List renderPng(GeneratedImageModel image) => encodePng(
    width: image.width,
    height: image.height,
    pixels: PsychedelicRecipe.fromSeed(
      image.seed,
    ).renderRgb(image.width, image.height),
    color: PngColor.rgb,
  );
}
