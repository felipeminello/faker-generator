/// Limits and defaults for the size of a generated image, in pixels.
abstract final class ImageSize {
  /// Smallest side accepted.
  static const min = 1;

  /// Largest side accepted: 4096×4096 is already 48 MB of raw pixels.
  static const max = 4096;

  static const defaultWidth = 1024;
  static const defaultHeight = 768;

  /// [value] brought into [min]..[max].
  static int clamp(int value) => value.clamp(min, max);
}

/// A common image size offered as a shortcut next to the fields.
class ImageSizePreset {
  const ImageSizePreset(this.width, this.height);

  final int width;
  final int height;

  /// "1024×768".
  String get label => '$width×$height';

  /// The sizes offered: the default first, then screens, social posts and a
  /// phone-shaped one.
  static const all = [
    ImageSizePreset(ImageSize.defaultWidth, ImageSize.defaultHeight),
    ImageSizePreset(800, 600),
    ImageSizePreset(1280, 720),
    ImageSizePreset(1920, 1080),
    ImageSizePreset(1080, 1080),
    ImageSizePreset(1080, 1920),
  ];
}
