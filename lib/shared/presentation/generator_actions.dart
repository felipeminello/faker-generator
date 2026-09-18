import 'package:flutter/material.dart';

import 'copy_to_clipboard.dart';
import 'responsive.dart';

/// "Gerar / Copiar / Limpar" action bar shared by every generator feature.
///
/// On wide windows the three actions sit side by side; on phones they stack,
/// so the generate button keeps its full width instead of being squeezed
/// until its label wraps one letter per line.
class GeneratorActions extends StatelessWidget {
  const GeneratorActions({
    super.key,
    required this.value,
    required this.onGenerate,
    required this.onClear,
    this.generateLabel = 'Gerar',
  });

  /// The currently generated value, or `null` when there is nothing to copy.
  final String? value;

  final VoidCallback onGenerate;
  final VoidCallback onClear;

  /// Label for the generate button while nothing has been generated yet.
  final String generateLabel;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;

    final generate = FilledButton.icon(
      onPressed: onGenerate,
      icon: const Icon(Icons.refresh),
      label: Text(hasValue ? 'Gerar novo' : generateLabel),
    );
    final copy = OutlinedButton.icon(
      onPressed: hasValue ? () => copyToClipboard(context, value!) : null,
      icon: const Icon(Icons.copy),
      label: const Text('Copiar'),
    );
    final clear = IconButton.outlined(
      onPressed: hasValue ? onClear : null,
      tooltip: 'Limpar',
      icon: const Icon(Icons.close),
    );

    if (isCompact(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 48, child: generate),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: SizedBox(height: 48, child: copy)),
              const SizedBox(width: 12),
              clear,
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: generate),
        const SizedBox(width: 12),
        copy,
        const SizedBox(width: 12),
        clear,
      ],
    );
  }
}
