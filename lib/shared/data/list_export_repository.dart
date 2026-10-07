import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'export_format.dart';
import 'save_file.dart';

/// Where exporting a list stands. The page shows a message when it leaves
/// [saving].
enum ExportStatus { idle, saving, saved, cancelled, failed }

/// Saves generated lists as CSV, JSON or TXT files through the platform's
/// "save as" dialog (a file dialog on desktop, the system document picker on
/// phones).
class ListExportRepository {
  ListExportRepository({SaveFile? saveFile})
    : _saveFile = saveFile ?? _filePickerSave;

  final SaveFile _saveFile;

  /// Saves [values] as `<fileName>.<extension>` in [format], with [column]
  /// heading the CSV. Returns where it was saved, or `null` when the user
  /// cancelled.
  Future<Uri?> save({
    required String fileName,
    required String column,
    required List<String> values,
    required ExportFormat format,
  }) => _saveFile(
    fileName: '$fileName.${format.extension}',
    bytes: utf8.encode(format.encode(column, values)),
    mimeType: format.mimeType,
  );

  static Future<Uri?> _filePickerSave({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) => FilePicker.saveFile(
    dialogTitle: 'Exportar lista',
    fileName: fileName,
    bytes: bytes,
    mimeType: mimeType,
  );
}
