import 'dart:typed_data';

/// Asks the user where to save [bytes] and writes them there; resolves to
/// where the file went, or `null` when the user cancelled.
///
/// The repositories that save files take one of these, so tests can stand in
/// for the platform's "save as" dialog.
typedef SaveFile =
    Future<Uri?> Function({
      required String fileName,
      required Uint8List bytes,
      required String mimeType,
    });
