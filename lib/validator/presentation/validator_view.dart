import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/presentation/copy_to_clipboard.dart';
import '../../shared/presentation/feature_header.dart';
import '../../shared/presentation/monospace.dart';
import '../../shared/presentation/responsive.dart';
import '../../shared/presentation/value_list_card.dart';
import '../data/document_validation.dart';

/// Presentation widget for the CPF and CNPJ validator.
///
/// Like `CronView` it holds no business logic: `ValidatorPage` passes the
/// text and the verdicts, and receives the user's intent through callbacks.
class ValidatorView extends StatelessWidget {
  const ValidatorView({
    super.key,
    required this.text,
    required this.results,
    required this.validCount,
    required this.invalidCount,
    required this.onTextChanged,
    required this.onExample,
    required this.onClear,
  });

  /// The values to check, one per line, as typed.
  final String text;

  /// One verdict per value, in order.
  final List<DocumentValidation> results;

  final int validCount;
  final int invalidCount;

  final ValueChanged<String> onTextChanged;
  final VoidCallback onExample;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Only the actions are pinned; a pasted column can be long, so
              // the verdicts are built as they scroll into view.
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const FeatureHeader(
                            icon: Icons.fact_check,
                            title: 'Validar CPF e CNPJ',
                            description:
                                'Cole um ou vários, um por linha, com ou sem '
                                'pontuação; até uma coluna de planilha ou uma '
                                'lista JSON. Cada um é reconhecido como CPF ou '
                                'CNPJ, inclusive o alfanumérico, e conferido '
                                'na hora.',
                          ),
                          const SizedBox(height: 20),
                          _TextInput(text: text, onChanged: onTextChanged),
                          const SizedBox(height: 16),
                          if (results.isEmpty)
                            const ValueListCard(
                              values: [],
                              emptyText: 'Nenhum valor para validar ainda',
                            )
                          else
                            _Summary(
                              validCount: validCount,
                              invalidCount: invalidCount,
                            ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    SliverList.separated(
                      itemCount: results.length,
                      itemBuilder: (context, index) =>
                          _ResultTile(result: results[index]),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Actions(
                hasText: text.isNotEmpty,
                onPaste: () => _paste(),
                onExample: onExample,
                onClear: onClear,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Replaces the text with what is on the clipboard, if it holds text.
  Future<void> _paste() async {
    final pasted = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    if (pasted != null && pasted.isNotEmpty) onTextChanged(pasted);
  }
}

/// Multi-line field kept in sync with the text held by the Bloc.
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
    // "Colar", "Ver exemplo" and "Limpar" replace the text in the Bloc;
    // mirror them here. While typing, the two already agree.
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
      minLines: 3,
      maxLines: 6,
      keyboardType: TextInputType.multiline,
      autocorrect: false,
      enableSuggestions: false,
      style: monospaceFont,
      decoration: const InputDecoration(
        labelText: 'CPFs e CNPJs, um por linha',
        hintText: '123.456.789-09\n12.ABC.345/01DE-35',
        alignLabelWithHint: true,
        border: OutlineInputBorder(),
      ),
      onChanged: widget.onChanged,
    );
  }
}

/// How many values passed and how many did not.
class _Summary extends StatelessWidget {
  const _Summary({required this.validCount, required this.invalidCount});

  final int validCount;
  final int invalidCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.titleSmall;

    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        Text(
          '$validCount ${validCount == 1 ? 'válido' : 'válidos'}',
          style: style?.copyWith(color: theme.colorScheme.primary),
        ),
        Text(
          '$invalidCount ${invalidCount == 1 ? 'inválido' : 'inválidos'}',
          style: style?.copyWith(
            color: invalidCount == 0
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.error,
          ),
        ),
      ],
    );
  }
}

/// The verdict on one value: what it is, what is wrong, and the fix.
class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result});

  final DocumentValidation result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final color = result.isValid
        ? theme.colorScheme.primary
        : theme.colorScheme.error;
    final suggestion = result.suggestion;
    final copyValue = suggestion ?? (result.isValid ? result.formatted : null);
    final note = result.isValid
        ? result.details.join(' · ')
        : result.explanation;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              result.isValid ? Icons.check_circle : Icons.error,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.formatted ?? result.input,
                  style: theme.textTheme.titleMedium?.merge(monospaceFont),
                ),
                const SizedBox(height: 2),
                Text(
                  result.title,
                  style: theme.textTheme.labelLarge?.copyWith(color: color),
                ),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    note,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
                if (suggestion != null) ...[
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: switch (result.problem) {
                            DocumentProblem.length => 'Com zeros à esquerda: ',
                            _ => 'Com os dígitos certos: ',
                          },
                        ),
                        TextSpan(text: suggestion, style: monospaceFont),
                      ],
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          if (copyValue != null)
            IconButton(
              onPressed: () => copyToClipboard(context, copyValue),
              tooltip: suggestion != null ? 'Copiar corrigido' : 'Copiar',
              icon: const Icon(Icons.copy, size: 20),
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }
}

/// "Colar / Ver exemplo / Limpar", laid out like `GeneratorActions`.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.hasText,
    required this.onPaste,
    required this.onExample,
    required this.onClear,
  });

  final bool hasText;
  final VoidCallback onPaste;
  final VoidCallback onExample;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final paste = FilledButton.icon(
      onPressed: onPaste,
      icon: const Icon(Icons.content_paste),
      label: const Text('Colar'),
    );
    final example = OutlinedButton.icon(
      onPressed: onExample,
      icon: const Icon(Icons.lightbulb_outline),
      label: const Text('Ver exemplo'),
    );
    final clear = IconButton.outlined(
      onPressed: hasText ? onClear : null,
      tooltip: 'Limpar',
      icon: const Icon(Icons.close),
    );

    if (isCompact(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 48, child: paste),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: SizedBox(height: 48, child: example)),
              const SizedBox(width: 12),
              clear,
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: paste),
        const SizedBox(width: 12),
        example,
        const SizedBox(width: 12),
        clear,
      ],
    );
  }
}
