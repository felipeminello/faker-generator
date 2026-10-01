import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/qr_code_bloc.dart';
import 'qr_code_view.dart';

/// Presentation page for the QR Code generator feature.
class QrCodePage extends StatelessWidget {
  const QrCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<QrCodeBloc, QrCodeState>(
      listenWhen: (previous, current) => previous.download != current.download,
      listener: _showDownloadResult,
      child: BlocBuilder<QrCodeBloc, QrCodeState>(
        builder: (context, state) {
          final bloc = context.read<QrCodeBloc>();

          return QrCodeView(
            text: state.text,
            level: state.level,
            qrCode: state.qrCode,
            error: state.error,
            onTextChanged: (text) => bloc.add(QrCodeTextChanged(text)),
            onLevelChanged: (level) => bloc.add(QrCodeLevelChanged(level)),
            onGenerate: () => bloc.add(const QrCodeRequested()),
            onClear: () => bloc.add(const QrCodeCleared()),
            onDownload: state.canDownload
                ? () => bloc.add(const QrCodeDownloadRequested())
                : null,
          );
        },
      ),
    );
  }

  /// Confirms where the PNG went, or that it could not be saved. A
  /// cancelled dialog needs no message.
  void _showDownloadResult(BuildContext context, QrCodeState state) {
    final message = switch (state.download) {
      QrCodeDownloadStatus.saved => _savedMessage(state.savedTo),
      QrCodeDownloadStatus.failed => 'Não foi possível salvar o QR Code',
      _ => null,
    };
    if (message == null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
      );
  }

  /// A file path on desktop; on phones the location is a `content:` URI
  /// that means nothing to the user, so it is left out.
  static String _savedMessage(Uri? savedTo) => savedTo?.scheme == 'file'
      ? 'QR Code salvo em ${savedTo!.toFilePath()}'
      : 'QR Code salvo';
}
