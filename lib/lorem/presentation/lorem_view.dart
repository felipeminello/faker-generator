import 'package:flutter/material.dart';

import '../../shared/presentation/count_field.dart';
import '../../shared/presentation/generator_actions.dart';
import '../../shared/presentation/responsive.dart';
import '../data/lorem_model.dart';
import '../data/lorem_unit.dart';

/// Presentation widget for the Lorem Ipsum generator.
///
/// Like `GeneratorView` it holds no business logic: `LoremPage` passes the
/// current options and text, and receives the user's intent through callbacks.
class LoremView extends StatelessWidget {
  const LoremView({
    super.key,
    required this.unit,
    required this.count,
    required this.startWithLorem,
    required this.lorem,
    required this.onUnitChanged,
    required this.onCountChanged,
    required this.onOpeningToggled,
    required this.onGenerate,
    required this.onClear,
  });

  /// Unit the [count] refers to.
  final LoremUnit unit;

  /// How many [unit]s to generate.
  final int count;

  /// Whether the text opens with "Lorem ipsum dolor sit amet...".
  final bool startWithLorem;

  /// The generated text, or `null` when nothing has been generated.
  final LoremModel? lorem;

  final ValueChanged<LoremUnit> onUnitChanged;
  final ValueChanged<int> onCountChanged;
  final ValueChanged<bool> onOpeningToggled;
  final VoidCallback onGenerate;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = lorem?.text;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Only the stats and the actions are pinned: everything above
              // scrolls, so a long text (or a short window) never overflows.
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.article,
                            size: 32,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Lorem Ipsum',
                              style: theme.textTheme.headlineSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Texto genérico para placeholder, no estilo do '
                        'lipsum.com. Escolha a unidade e a quantidade.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _Options(
                        unit: unit,
                        count: count,
                        startWithLorem: startWithLorem,
                        onUnitChanged: onUnitChanged,
                        onCountChanged: onCountChanged,
                        onOpeningToggled: onOpeningToggled,
                      ),
                      const SizedBox(height: 20),
                      _ResultCard(text: text),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                lorem == null
                    ? '${unit.min} a ${unit.max} ${unit.hint}'
                    : '${lorem!.wordCount} palavras · '
                          '${lorem!.characterCount} caracteres',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              GeneratorActions(
                value: text,
                onGenerate: onGenerate,
                onClear: onClear,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Unit selector, amount field and the "start with Lorem ipsum" switch.
class _Options extends StatelessWidget {
  const _Options({
    required this.unit,
    required this.count,
    required this.startWithLorem,
    required this.onUnitChanged,
    required this.onCountChanged,
    required this.onOpeningToggled,
  });

  final LoremUnit unit;
  final int count;
  final bool startWithLorem;
  final ValueChanged<LoremUnit> onUnitChanged;
  final ValueChanged<int> onCountChanged;
  final ValueChanged<bool> onOpeningToggled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // A Card (and not a plain Container) so the switch tile has a Material
    // ancestor to paint its ink on.
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact(context) ? 12 : 20,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<LoremUnit>(
                segments: [
                  for (final value in LoremUnit.values)
                    ButtonSegment(value: value, label: Text(value.label)),
                ],
                selected: {unit},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    onUnitChanged(selection.first),
              ),
            ),
            const SizedBox(height: 16),
            CountField(
              label: 'Quantidade de ${unit.hint}',
              count: count,
              min: unit.min,
              max: unit.max,
              onChanged: onCountChanged,
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              value: startWithLorem,
              onChanged: onOpeningToggled,
              contentPadding: EdgeInsets.zero,
              title: const Text('Começar com "Lorem ipsum dolor sit amet..."'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card holding the generated text (or the empty state).
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: text == null
          ? Center(
              child: Text(
                'Nenhum texto gerado ainda',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : SelectableText(
              text!,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
    );
  }
}
