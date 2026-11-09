import 'dart:isolate';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../shared/data/save_file.dart';
import 'generated_image_model.dart';
import 'image_generator_repository.dart';

/// Renders an image as a PNG at its full size.
typedef ImageRenderer = Future<Uint8List> Function(GeneratedImageModel image);

/// Saves generated images as PNG files through the platform's "save as"
/// dialog (a file dialog on desktop, the system document picker on phones).
class ImageDownloadRepository {
  ImageDownloadRepository({SaveFile? saveFile, ImageRenderer? render})
    : _saveFile = saveFile ?? _filePickerSave,
      _render = render ?? _renderInIsolate;

  final SaveFile _saveFile;
  final ImageRenderer _render;

  /// Renders [image] at its full size and saves it. Returns where it was
  /// saved, or `null` when the user cancelled.
  Future<Uri?> save(GeneratedImageModel image) async => _saveFile(
    fileName: image.fileName,
    bytes: await _render(image),
    mimeType: 'image/png',
  );

  /// Big images take seconds to draw; off the UI isolate the page keeps
  /// responding meanwhile.
  static Future<Uint8List> _renderInIsolate(GeneratedImageModel image) =>
      Isolate.run(() => ImageGeneratorRepository.renderPng(image));

  static Future<Uri?> _filePickerSave({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) => FilePicker.saveFile(
    dialogTitle: 'Salvar imagem',
    fileName: fileName,
    bytes: bytes,
    mimeType: mimeType,
    type: FileType.image,
  );
}
