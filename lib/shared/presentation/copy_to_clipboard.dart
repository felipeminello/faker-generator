import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Copies [text] to the clipboard and confirms it with a snack bar.
///
/// Shared by every generator page so the copy feedback is identical across
/// features.
Future<void> copyToClipboard(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text('Copiado para a área de transferência'),
        duration: Duration(seconds: 2),
      ),
    );
}
