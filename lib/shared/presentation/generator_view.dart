import 'package:flutter/material.dart';

import 'copy_to_clipboard.dart';

/// Reusable presentation widget shared by every generator feature
/// (UUID, CPF, CNPJ).
///
/// It is intentionally free of business logic: pages wire a Bloc to it by
/// passing the current [value] plus the [onGenerate]/[onClear] callbacks.
class GeneratorView extends StatelessWidget {
  const GeneratorView({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.value,
    required this.onGenerate,
    required this.onClear,
    this.generateLabel = 'Gerar',
  });

  /// Feature title shown above the result.
  final String title;

  /// Short explanation of what the feature generates.
  final String description;

  /// Icon representing the feature.
  final IconData icon;

  /// The currently generated value, or `null` when nothing has been generated.
  final String? value;

  /// Called when the user asks for a new value.
  final VoidCallback onGenerate;

  /// Called when the user clears the current value.
  final VoidCallback onClear;

  /// Label for the generate button.
  final String generateLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = value != null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, size: 32, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(title, style: theme.textTheme.headlineSmall),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              _ResultCard(value: value),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onGenerate,
                      icon: const Icon(Icons.refresh),
                      label: Text(hasValue ? 'Gerar novo' : generateLabel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: hasValue
                        ? () => copyToClipboard(context, value!)
                        : null,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar'),
                  ),
                  const SizedBox(width: 12),
                  IconButton.outlined(
                    onPressed: hasValue ? onClear : null,
                    tooltip: 'Limpar',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.value});

  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Center(
        child: value == null
            ? Text(
                'Nenhum valor gerado ainda',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            : SelectableText(
                value!,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFamily: 'monospace',
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
      ),
    );
  }
}
