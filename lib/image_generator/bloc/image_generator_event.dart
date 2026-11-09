part of 'image_generator_bloc.dart';

/// Events accepted by [ImageGeneratorBloc].
sealed class ImageGeneratorEvent {
  const ImageGeneratorEvent();
}

/// The width field was edited. Out-of-range values are clamped.
class ImageWidthChanged extends ImageGeneratorEvent {
  const ImageWidthChanged(this.width);

  final int width;
}

/// The height field was edited. Out-of-range values are clamped.
class ImageHeightChanged extends ImageGeneratorEvent {
  const ImageHeightChanged(this.height);

  final int height;
}

/// A ready-made size was picked.
class ImageSizeSelected extends ImageGeneratorEvent {
  const ImageSizeSelected(this.width, this.height);

  final int width;
  final int height;
}

/// Requests a new picture at the current size.
class ImageRequested extends ImageGeneratorEvent {
  const ImageRequested();
}

/// Drops the picture, keeping the size.
class ImageCleared extends ImageGeneratorEvent {
  const ImageCleared();
}

/// Saves the picture on screen as a PNG at its full size, asking the user
/// where.
class ImageDownloadRequested extends ImageGeneratorEvent {
  const ImageDownloadRequested();
}
