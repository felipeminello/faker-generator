import 'package:flutter/material.dart';

import '../../shared/presentation/generator_actions.dart';
import '../../shared/presentation/responsive.dart';
import '../data/qr_code_level.dart';
import '../data/qr_code_model.dart';
import 'qr_code_painter.dart';

/// Presentation widget for the QR Code generator.
///
/// Like `CronView` it holds no business logic: `QrCodePage` passes the text,
/// the level and the encoded code, and receives the user's intent through
/// callbacks.
class QrCodeView extends StatelessWidget {
  const QrCodeView({
    super.key,
    required this.text,
    required this.level,
    required this.qrCode,
    required this.error,
    required this.onTextChanged,
    required this.onLevelChanged,
    required this.onGenerate,
    required this.onClear,
  });

  /// The text being encoded.
  final String text;

  /// Error correction level.
  final QrCodeLevel level;

  /// The encoded code, when [text] fits.
  final QrCodeModel? qrCode;

  /// Why [text] could not be encoded, when it does not fit.
  final QrCodeTooLongException? error;

  final ValueChanged<String> onTextChanged;
  final ValueChanged<QrCodeLevel> onLevelChanged;
  final VoidCallback onGenerate;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Only the actions are pinned: the code plus the options are
              // taller than a phone, so the rest scrolls.
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            size: 32,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'QR Code',
                              style: theme.textTheme.headlineSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Escreva um texto ou link e o QR Code aparece na '
                        'hora. "Gerar" cria um conteúdo de exemplo.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _Options(
                        text: text,
                        level: level,
                        onTextChanged: onTextChanged,
                        onLevelChanged: onLevelChanged,
                      ),
                      const SizedBox(height: 20),
                      _Preview(qrCode: qrCode, error: error),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GeneratorActions(
                value: text.isEmpty ? null : text,
                onGenerate: onGenerate,
                onClear: onClear,
                regenerateLabel: 'Gerar outro',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Text to encode and the error correction level.
class _Options extends StatelessWidget {
  const _Options({
    required this.text,
    required this.level,
    required this.onTextChanged,
    required this.onLevelChanged,
  });

  final String text;
  final QrCodeLevel level;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<QrCodeLevel> onLevelChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          _TextInput(text: text, onChanged: onTextChanged),
          const SizedBox(height: 16),
          Text('Correção de erros', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<QrCodeLevel>(
            segments: [
              for (final value in QrCodeLevel.values)
                ButtonSegment(
                  value: value,
                  label: Text(value.label),
                  tooltip: '~${value.recovery}%',
                ),
            ],
            selected: {level},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => onLevelChanged(selection.first),
          ),
          const SizedBox(height: 8),
          Text(
            'Nível ${level.label}: lê mesmo com ~${level.recovery}% do código '
            'danificado. Níveis mais altos geram códigos maiores.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Text field kept in sync with the text held by the Bloc.
class _TextInput extends StatefulWidget {
  const _TextInput({required this.text, required this.onChanged});

  final String text;
  final ValueChanged<String> onChanged;

  @override
  State<_TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<_TextInput> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );

  @override
  void didUpdateWidget(_TextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // "Gerar" and "Limpar" replace the text in the Bloc; mirror them here.
    // While typing, the two already agree.
    if (widget.text != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.text,
        selection: TextSelection.collapsed(offset: widget.text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      minLines: 1,
      maxLines: 5,
      keyboardType: TextInputType.multiline,
      autocorrect: false,
      decoration: const InputDecoration(
        labelText: 'Conteúdo',
        hintText: 'Texto, link, e-mail, telefone...',
        border: OutlineInputBorder(),
      ),
      onChanged: widget.onChanged,
    );
  }
}

/// The code (or the empty state, or why the text does not fit) and its size.
class _Preview extends StatelessWidget {
  const _Preview({required this.qrCode, required this.error});

  final QrCodeModel? qrCode;
  final QrCodeTooLongException? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qrCode = this.qrCode;
    final error = this.error;
    final muted = theme.colorScheme.onSurfaceVariant;

    final Widget content;
    if (qrCode != null) {
      content = Semantics(
        image: true,
        label: 'QR Code de: ${qrCode.text}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CustomPaint(
            painter: QrCodePainter(qrCode),
            child: const SizedBox.expand(),
          ),
        ),
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              error == null ? Icons.qr_code_2 : Icons.error_outline,
              size: 48,
              color: error == null ? muted : theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              error?.message ?? 'Nenhum QR Code ainda',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: error == null ? muted : theme.colorScheme.error,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: qrCode == null
                    ? theme.colorScheme.surfaceContainerHighest
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              padding: const EdgeInsets.all(4),
              child: content,
            ),
          ),
        ),
        if (qrCode != null) ...[
          const SizedBox(height: 12),
          Text(
            'Versão ${qrCode.version} · ${qrCode.size}×${qrCode.size} '
            'módulos · ${qrCode.byteCount} '
            '${qrCode.byteCount == 1 ? 'byte' : 'bytes'}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ],
    );
  }
}
