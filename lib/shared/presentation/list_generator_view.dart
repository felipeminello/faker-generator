import 'package:flutter/material.dart';

import '../data/export_format.dart';
import 'export_button.dart';
import 'feature_header.dart';
import 'generator_actions.dart';
import 'responsive.dart';
import 'value_list_card.dart';

/// Presentation widget shared by the generators that make lists (CPF, CNPJ):
/// header, the feature's [options], the values and the
/// "Gerar / Copiar / Exportar / Limpar" actions.
///
/// Like `GeneratorView` it holds no business logic: the page passes the
/// values and receives the user's intent through callbacks. Generating
/// scrolls the values into view, since the options above them fill most of a
/// phone or a short window.
class ListGeneratorView extends StatefulWidget {
  const ListGeneratorView({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.options,
    required this.values,
    required this.regenerateLabel,
    required this.onGenerate,
    required this.onClear,
    required this.onExport,
  });

  final String title;
  final String description;
  final IconData icon;

  /// The feature's option controls, shown in a card above the values.
  final Widget options;

  /// The values on screen; empty when nothing has been generated.
  final List<String> values;

  /// Label for the generate button once there are values on screen.
  final String regenerateLabel;

  final VoidCallback onGenerate;
  final VoidCallback onClear;

  /// Saves the values in the picked format; `null` while there is nothing to
  /// save (or a save is under way).
  final ValueChanged<ExportFormat>? onExport;

  @override
  State<ListGeneratorView> createState() => _ListGeneratorViewState();
}

class _ListGeneratorViewState extends State<ListGeneratorView> {
  final _valuesKey = GlobalKey();

  /// Asks for new values, then, once they are laid out, scrolls just enough
  /// for the whole list to show.
  void _generate() {
    widget.onGenerate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final values = _valuesKey.currentContext;
      if (values == null || !values.mounted) return;
      Scrollable.ensureVisible(
        values,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final values = widget.values;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Only the actions are pinned: the options plus a list are
              // taller than a phone, so the rest scrolls.
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FeatureHeader(
                        icon: widget.icon,
                        title: widget.title,
                        description: widget.description,
                      ),
                      const SizedBox(height: 20),
                      // A Card (and not a plain Container) so the switch
                      // tiles have a Material ancestor to paint their ink on.
                      Card(
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        color: theme.colorScheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact(context) ? 12 : 20,
                            vertical: 16,
                          ),
                          child: widget.options,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ValueListCard(key: _valuesKey, values: values),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GeneratorActions(
                value: values.isEmpty ? null : values.join('\n'),
                onGenerate: _generate,
                onClear: widget.onClear,
                regenerateLabel: widget.regenerateLabel,
                extraAction: ExportButton(onExport: widget.onExport),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
