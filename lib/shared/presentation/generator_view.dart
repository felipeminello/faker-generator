import 'package:flutter/material.dart';

import 'generator_actions.dart';
import 'responsive.dart';

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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: pagePadding(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, size: 32, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title, style: theme.textTheme.headlineSmall),
                  ),
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
              GeneratorActions(
                value: value,
                onGenerate: onGenerate,
                onClear: onClear,
                generateLabel: generateLabel,
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

    final compact = isCompact(context);
    final valueStyle =
        (compact ? theme.textTheme.titleMedium : theme.textTheme.headlineSmall)
            ?.copyWith(
              fontFamily: 'monospace',
              fontFeatures: const [FontFeature.tabularFigures()],
            );

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 96),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 24,
        vertical: compact ? 20 : 28,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Center(
        child: value == null
            ? Text(
                'Nenhum valor gerado ainda',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            // A UUID is 36 characters wide: on a phone it would overflow the
            // card, so the text shrinks instead of wrapping mid-value.
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: SelectableText(
                  value!,
                  textAlign: TextAlign.center,
                  style: valueStyle,
                ),
              ),
      ),
    );
  }
}
