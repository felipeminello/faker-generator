import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/qr_code_bloc.dart';
import 'qr_code_view.dart';

/// Presentation page for the QR Code generator feature.
class QrCodePage extends StatelessWidget {
  const QrCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QrCodeBloc, QrCodeState>(
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
        );
      },
    );
  }
}
