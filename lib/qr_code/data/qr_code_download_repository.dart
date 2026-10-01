import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'qr_code_model.dart';
import 'qr_code_png.dart';

/// Asks the user where to save [bytes] and writes them there; resolves to
/// where the file went, or `null` when the user cancelled.
typedef SaveFile =
    Future<Uri?> Function({
      required String fileName,
      required Uint8List bytes,
      required String mimeType,
    });

/// Saves QR Codes as PNG images through the platform's "save as" dialog
/// (a file dialog on desktop, the system document picker on phones).
class QrCodeDownloadRepository {
  QrCodeDownloadRepository({SaveFile? saveFile})
    : _saveFile = saveFile ?? _filePickerSave;

  final SaveFile _saveFile;

  /// Side of the saved image, in pixels.
  static const imageSize = 512;

  /// File name the dialog suggests.
  static const fileName = 'qrcode.png';

  /// Saves [qrCode] as a [imageSize]×[imageSize] PNG. Returns where it was
  /// saved, or `null` when the user cancelled.
  Future<Uri?> save(QrCodeModel qrCode) => _saveFile(
    fileName: fileName,
    bytes: encodeQrCodePng(qrCode, size: imageSize),
    mimeType: 'image/png',
  );

  static Future<Uri?> _filePickerSave({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) => FilePicker.saveFile(
    dialogTitle: 'Salvar QR Code',
    fileName: fileName,
    bytes: bytes,
    mimeType: mimeType,
    type: FileType.image,
  );
}
