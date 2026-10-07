import 'dart:convert';
import 'dart:typed_data';

/// Stands in for the "save as" dialog: records each save and answers with
/// [result] (a [Uri], `null` for a cancelled dialog, or an [Exception] to
/// throw).
class FakeSaveDialog {
  FakeSaveDialog([this.result]);

  final Object? result;
  final saved = <({String fileName, String text, String mimeType})>[];

  Future<Uri?> call({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    saved.add((
      fileName: fileName,
      text: utf8.decode(bytes),
      mimeType: mimeType,
    ));
    if (result case final Exception error) throw error;
    return result as Uri?;
  }
}
