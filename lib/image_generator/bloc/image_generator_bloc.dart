import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/data/list_export_repository.dart';
import '../data/generated_image_model.dart';
import '../data/image_download_repository.dart';
import '../data/image_generator_repository.dart';
import '../data/image_size.dart';

part 'image_generator_event.dart';
part 'image_generator_state.dart';

/// Mediates between the image generator UI, the [ImageGeneratorRepository]
/// (new images and their previews) and the [ImageDownloadRepository]
/// (saving as PNG).
///
/// Resizing keeps the picture: the same seed is drawn again at the new
/// proportions, so the preview follows the size as it is typed.
class ImageGeneratorBloc
    extends Bloc<ImageGeneratorEvent, ImageGeneratorState> {
  ImageGeneratorBloc(this._repository, this._downloads)
    : super(const ImageGeneratorState()) {
    on<ImageWidthChanged>(
      (event, emit) => _resize(event.width, state.height, emit),
    );
    on<ImageHeightChanged>(
      (event, emit) => _resize(state.width, event.height, emit),
    );
    on<ImageSizeSelected>(
      (event, emit) => _resize(event.width, event.height, emit),
    );
    on<ImageRequested>(_onRequested);
    on<ImageCleared>(_onCleared);
    on<ImageDownloadRequested>(_onDownloadRequested);
  }

  final ImageGeneratorRepository _repository;
  final ImageDownloadRepository _downloads;

  void _resize(int width, int height, Emitter<ImageGeneratorState> emit) {
    width = ImageSize.clamp(width);
    height = ImageSize.clamp(height);
    if (width == state.width && height == state.height) return;
    emit(_withImage(width, height, state.image?.resized(width, height)));
  }

  void _onRequested(ImageRequested event, Emitter<ImageGeneratorState> emit) {
    emit(
      _withImage(
        state.width,
        state.height,
        _repository.generate(state.width, state.height),
      ),
    );
  }

  void _onCleared(ImageCleared event, Emitter<ImageGeneratorState> emit) {
    emit(_withImage(state.width, state.height, null));
  }

  /// Saves the image that is on screen when the user asks, even if the size
  /// changes while the dialog is open.
  Future<void> _onDownloadRequested(
    ImageDownloadRequested event,
    Emitter<ImageGeneratorState> emit,
  ) async {
    final image = state.image;
    if (image == null || !state.canDownload) return;

    emit(state.withDownload(ExportStatus.saving));
    try {
      final savedTo = await _downloads.save(image);
      emit(
        savedTo == null
            ? state.withDownload(ExportStatus.cancelled)
            : state.withDownload(ExportStatus.saved, savedTo: savedTo),
      );
    } on Exception {
      emit(state.withDownload(ExportStatus.failed));
    }
  }

  /// The state for a [width]×[height] [image] (and its preview), keeping
  /// where the download stands.
  ImageGeneratorState _withImage(
    int width,
    int height,
    GeneratedImageModel? image,
  ) => ImageGeneratorState(
    width: width,
    height: height,
    image: image,
    preview: image == null ? null : _repository.preview(image),
    download: state.download,
    savedTo: state.savedTo,
  );
}
