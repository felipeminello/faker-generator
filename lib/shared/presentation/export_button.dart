import 'package:flutter/material.dart';

import '../data/export_format.dart';
import '../data/list_export_repository.dart';

/// "Exportar" button that opens a menu with one entry per [ExportFormat].
class ExportButton extends StatelessWidget {
  const ExportButton({super.key, required this.onExport});

  /// Receives the format picked; `null` disables the button.
  final ValueChanged<ExportFormat>? onExport;

  @override
  Widget build(BuildContext context) {
    final onExport = this.onExport;

    return MenuAnchor(
      menuChildren: [
        for (final format in ExportFormat.values)
          MenuItemButton(
            onPressed: onExport == null ? null : () => onExport(format),
            child: Text('${format.label} · ${format.hint}'),
          ),
      ],
      builder: (context, controller, _) => OutlinedButton.icon(
        onPressed: onExport == null
            ? null
            : () => controller.isOpen ? controller.close() : controller.open(),
        icon: const Icon(Icons.download),
        label: const Text('Exportar'),
      ),
    );
  }
}

/// Confirms where an exported list went, or that it could not be saved. A
/// cancelled dialog needs no message.
void showExportResult(BuildContext context, ExportStatus status, Uri? savedTo) {
  final message = switch (status) {
    // A file path on desktop; on phones the location is a `content:` URI
    // that means nothing to the user, so it is left out.
    ExportStatus.saved when savedTo?.scheme == 'file' =>
      'Lista salva em ${savedTo!.toFilePath()}',
    ExportStatus.saved => 'Lista salva',
    ExportStatus.failed => 'Não foi possível salvar a lista',
    _ => null,
  };
  if (message == null) return;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
}
