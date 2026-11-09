import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/data/list_export_repository.dart';
import '../bloc/image_generator_bloc.dart';
import 'image_generator_view.dart';

/// Presentation page for the image generator feature.
class ImageGeneratorPage extends StatelessWidget {
  const ImageGeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ImageGeneratorBloc, ImageGeneratorState>(
      listenWhen: (previous, current) => previous.download != current.download,
      listener: _showDownloadResult,
      child: BlocBuilder<ImageGeneratorBloc, ImageGeneratorState>(
        builder: (context, state) {
          final bloc = context.read<ImageGeneratorBloc>();

          return ImageGeneratorView(
            width: state.width,
            height: state.height,
            image: state.image,
            preview: state.preview,
            saving: state.download == ExportStatus.saving,
            onWidthChanged: (width) => bloc.add(ImageWidthChanged(width)),
            onHeightChanged: (height) => bloc.add(ImageHeightChanged(height)),
            onSizeSelected: (width, height) =>
                bloc.add(ImageSizeSelected(width, height)),
            onGenerate: () => bloc.add(const ImageRequested()),
            onClear: () => bloc.add(const ImageCleared()),
            onDownload: state.canDownload
                ? () => bloc.add(const ImageDownloadRequested())
                : null,
          );
        },
      ),
    );
  }

  /// Confirms where the PNG went, or that it could not be saved. A
  /// cancelled dialog needs no message.
  void _showDownloadResult(BuildContext context, ImageGeneratorState state) {
    final message = switch (state.download) {
      ExportStatus.saved => _savedMessage(state.savedTo),
      ExportStatus.failed => 'Não foi possível salvar a imagem',
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
      ? 'Imagem salva em ${savedTo!.toFilePath()}'
      : 'Imagem salva';
}
