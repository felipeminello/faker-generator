import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../shared/presentation/count_field.dart';
import '../../shared/presentation/feature_header.dart';
import '../../shared/presentation/generator_actions.dart';
import '../../shared/presentation/responsive.dart';
import '../data/generated_image_model.dart';
import '../data/image_size.dart';

/// Presentation widget for the image generator.
///
/// Like `QrCodeView` it holds no business logic: `ImageGeneratorPage` passes
/// the size, the picture and its preview, and receives the user's intent
/// through callbacks.
class ImageGeneratorView extends StatelessWidget {
  const ImageGeneratorView({
    super.key,
    required this.width,
    required this.height,
    required this.image,
    required this.preview,
    required this.saving,
    required this.onWidthChanged,
    required this.onHeightChanged,
    required this.onSizeSelected,
    required this.onGenerate,
    required this.onClear,
    required this.onDownload,
  });

  /// Chosen size, in pixels.
  final int width;
  final int height;

  /// The generated picture, if any.
  final GeneratedImageModel? image;

  /// [image] as a small PNG.
  final Uint8List? preview;

  /// Whether the picture is being rendered or saved.
  final bool saving;

  final ValueChanged<int> onWidthChanged;
  final ValueChanged<int> onHeightChanged;
  final void Function(int width, int height) onSizeSelected;
  final VoidCallback onGenerate;
  final VoidCallback onClear;

  /// Saves the picture as a PNG; `null` while there is nothing to save (or a
  /// save is under way).
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Only the actions are pinned: the options plus the preview
              // are taller than a phone, so the rest scrolls.
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FeatureHeader(
                        icon: Icons.palette,
                        title: 'Imagem',
                        description:
                            'Imagens coloridas, no estilo psicodélico, para '
                            'testar upload, layout e placeholders. Cada uma é '
                            'desenhada por um algoritmo a partir de um número '
                            'sorteado, então nunca se repete. "Download" '
                            'salva em PNG no tamanho escolhido.',
                      ),
                      const SizedBox(height: 20),
                      _Options(
                        width: width,
                        height: height,
                        onWidthChanged: onWidthChanged,
                        onHeightChanged: onHeightChanged,
                        onSizeSelected: onSizeSelected,
                      ),
                      const SizedBox(height: 20),
                      _Preview(width: width, height: height, preview: preview),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GeneratorActions(
                value: image?.fileName,
                onGenerate: onGenerate,
                onClear: onClear,
                regenerateLabel: 'Gerar outra',
                secondaryAction: GeneratorSecondaryAction(
                  label: saving ? 'Salvando…' : 'Download',
                  icon: Icons.download,
                  onPressed: onDownload,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Width, height and the ready-made sizes.
class _Options extends StatelessWidget {
  const _Options({
    required this.width,
    required this.height,
    required this.onWidthChanged,
    required this.onHeightChanged,
    required this.onSizeSelected,
  });

  final int width;
  final int height;
  final ValueChanged<int> onWidthChanged;
  final ValueChanged<int> onHeightChanged;
  final void Function(int width, int height) onSizeSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final widthField = CountField(
      label: 'Largura (px)',
      count: width,
      min: ImageSize.min,
      max: ImageSize.max,
      onChanged: onWidthChanged,
    );
    final heightField = CountField(
      label: 'Altura (px)',
      count: height,
      min: ImageSize.min,
      max: ImageSize.max,
      onChanged: onHeightChanged,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact(context) ? 12 : 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Side by side only where each field keeps room for its label
          // next to the -/+ buttons.
          LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth >= 480
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: widthField),
                      const SizedBox(width: 16),
                      Expanded(child: heightField),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      widthField,
                      const SizedBox(height: 12),
                      heightField,
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Text('Tamanhos comuns', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in ImageSizePreset.all)
                ChoiceChip(
                  label: Text(preset.label),
                  selected: preset.width == width && preset.height == height,
                  showCheckmark: false,
                  onSelected: (_) =>
                      onSizeSelected(preset.width, preset.height),
                ),
              ActionChip(
                avatar: const Icon(Icons.swap_horiz),
                label: const Text('Inverter'),
                tooltip: 'Trocar largura e altura',
                onPressed: width == height
                    ? null
                    : () => onSizeSelected(height, width),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The picture (or the empty state) in a frame with its proportions, and
/// its size below.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.width,
    required this.height,
    required this.preview,
  });

  final int width;
  final int height;
  final Uint8List? preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = this.preview;
    final muted = theme.colorScheme.onSurfaceVariant;

    final Widget content;
    if (preview != null) {
      content = Semantics(
        image: true,
        label: 'Imagem psicodélica de $width×$height pixels',
        child: Image.memory(
          preview,
          fit: BoxFit.contain,
          // Keeps the old picture up while the next one decodes, so typing
          // a size does not flash an empty frame.
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        ),
      );
    } else {
      content = FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_outlined, size: 48, color: muted),
              const SizedBox(height: 12),
              Text(
                'Nenhuma imagem ainda',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: muted),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // The frame takes the image's proportions, within reason: a
        // 4096×1 strip would otherwise be an invisible line. The picture is
        // fitted inside, so it keeps its true shape either way.
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: AspectRatio(
            aspectRatio: (width / height).clamp(0.5, 2.5),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: content,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$width × $height pixels · PNG',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
      ],
    );
  }
}
