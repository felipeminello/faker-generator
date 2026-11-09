part of 'image_generator_bloc.dart';

/// State of the image generator: the chosen size, the picture (if one was
/// generated) and where its download stands.
class ImageGeneratorState {
  const ImageGeneratorState({
    this.width = ImageSize.defaultWidth,
    this.height = ImageSize.defaultHeight,
    this.image,
    this.preview,
    this.download = ExportStatus.idle,
    this.savedTo,
  });

  /// Size in pixels, already within `ImageSize.min`..`ImageSize.max`.
  final int width;
  final int height;

  /// The generated picture, at [width]×[height]; `null` before "Gerar" and
  /// after "Limpar".
  final GeneratedImageModel? image;

  /// [image] rendered as a small PNG for the page. It is derived from
  /// [image], so it is left out of `==`.
  final Uint8List? preview;

  /// Where the last download stands. It survives resizing, so a second
  /// download cannot start while the save dialog is still open.
  final ExportStatus download;

  /// Where the last download was saved, once it is [ExportStatus.saved].
  final Uri? savedTo;

  /// Whether there is a picture to clear or save.
  bool get hasImage => image != null;

  /// Whether there is a picture to download right now.
  bool get canDownload => image != null && download != ExportStatus.saving;

  /// This state with the download at [status] (and saved to [savedTo]).
  ImageGeneratorState withDownload(ExportStatus status, {Uri? savedTo}) =>
      ImageGeneratorState(
        width: width,
        height: height,
        image: image,
        preview: preview,
        download: status,
        savedTo: savedTo,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImageGeneratorState &&
          other.width == width &&
          other.height == height &&
          other.image == image &&
          other.download == download &&
          other.savedTo == savedTo);

  @override
  int get hashCode => Object.hash(width, height, image, download, savedTo);

  @override
  String toString() =>
      'ImageGeneratorState(${width}x$height, image: $image, '
      'download: ${download.name})';
}
