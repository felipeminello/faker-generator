/// A generated image: its size and the seed the picture is drawn from.
///
/// The pixels themselves are not kept: the same seed always draws the same
/// picture (see `PsychedelicRecipe`), at any size, so the preview and the
/// saved PNG are rendered from this on demand.
class GeneratedImageModel {
  const GeneratedImageModel({
    required this.width,
    required this.height,
    required this.seed,
  });

  /// Width in pixels.
  final int width;

  /// Height in pixels.
  final int height;

  /// Picks the colors and the pattern.
  final int seed;

  /// Name the save dialog suggests: "imagem-1024x768.png".
  String get fileName => 'imagem-${width}x$height.png';

  /// The same picture at another size.
  GeneratedImageModel resized(int width, int height) =>
      GeneratedImageModel(width: width, height: height, seed: seed);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GeneratedImageModel &&
          other.width == width &&
          other.height == height &&
          other.seed == seed);

  @override
  int get hashCode => Object.hash(width, height, seed);

  @override
  String toString() => 'GeneratedImageModel(${width}x$height, seed: $seed)';
}
