import 'package:flutter/material.dart';

import 'copy_to_clipboard.dart';
import 'monospace.dart';
import 'responsive.dart';

/// Card holding the generated values: an empty state, a single value in
/// large type, or a numbered list where tapping a row copies it.
class ValueListCard extends StatelessWidget {
  const ValueListCard({
    super.key,
    required this.values,
    this.emptyText = 'Nenhum valor gerado ainda',
  });

  final List<String> values;

  /// Shown while [values] is empty.
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decoration = BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: theme.colorScheme.outlineVariant),
    );

    if (values.length > 1) {
      return Container(
        height: 280,
        decoration: decoration,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            type: MaterialType.transparency,
            child: _ValueList(values: values),
          ),
        ),
      );
    }

    final compact = isCompact(context);
    final valueStyle =
        (compact ? theme.textTheme.titleMedium : theme.textTheme.headlineSmall)
            ?.copyWith(
              fontFamily: 'monospace',
              fontFeatures: const [FontFeature.tabularFigures()],
            );
    final value = values.firstOrNull;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 96),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 24,
        vertical: compact ? 20 : 28,
      ),
      decoration: decoration,
      child: Center(
        child: value == null
            ? Text(
                emptyText,
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
                  value,
                  textAlign: TextAlign.center,
                  style: valueStyle,
                ),
              ),
      ),
    );
  }
}

class _ValueList extends StatelessWidget {
  const _ValueList({required this.values});

  final List<String> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    // Wide enough for "1000".
    final indexWidth = values.length >= 1000 ? 40.0 : 32.0;

    return Scrollbar(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: values.length,
        itemBuilder: (context, index) => InkWell(
          onTap: () => copyToClipboard(context, values[index]),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: indexWidth,
                  child: Text(
                    '${index + 1}',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    values[index],
                    style: theme.textTheme.bodyLarge?.merge(monospaceFont),
                  ),
                ),
                Icon(Icons.copy, size: 18, color: muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
