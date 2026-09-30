import 'package:flutter/material.dart';

import '../../shared/presentation/generator_actions.dart';
import '../../shared/presentation/monospace.dart';
import '../../shared/presentation/responsive.dart';
import '../data/password_charset.dart';
import '../data/password_model.dart';
import '../data/password_options.dart';

/// Presentation widget for the password generator.
///
/// Like `LoremView` it holds no business logic: `PasswordPage` passes the
/// current options and password, and receives the user's intent through
/// callbacks.
class PasswordView extends StatelessWidget {
  const PasswordView({
    super.key,
    required this.options,
    required this.password,
    required this.onLengthChanged,
    required this.onCharsetToggled,
    required this.onSymbolToggled,
    required this.onSymbolsReset,
    required this.onGenerate,
    required this.onCopied,
    required this.onClear,
    required this.onShowRecent,
  });

  final PasswordOptions options;

  /// The password on screen, or `null` when nothing has been generated.
  final PasswordModel? password;

  final ValueChanged<int> onLengthChanged;
  final void Function(PasswordCharset charset, bool enabled) onCharsetToggled;
  final void Function(String symbol, bool selected) onSymbolToggled;
  final VoidCallback onSymbolsReset;
  final VoidCallback onGenerate;
  final VoidCallback onCopied;
  final VoidCallback onClear;
  final VoidCallback onShowRecent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = password?.value;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Only the actions are pinned: the options are long on a phone
              // (one chip per special character), so everything above scrolls.
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.password,
                            size: 32,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Senha',
                              style: theme.textTheme.headlineSmall,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: onShowRecent,
                            icon: const Icon(Icons.history),
                            label: const Text('Recentes'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Senha aleatória com os caracteres que você escolher. '
                        'As últimas geradas ficam salvas em Recentes.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _PasswordCard(value: value),
                      const SizedBox(height: 20),
                      _Options(
                        options: options,
                        onLengthChanged: onLengthChanged,
                        onCharsetToggled: onCharsetToggled,
                        onSymbolToggled: onSymbolToggled,
                        onSymbolsReset: onSymbolsReset,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GeneratorActions(
                value: value,
                onGenerate: onGenerate,
                onClear: onClear,
                onCopied: onCopied,
                regenerateLabel: 'Gerar nova',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card holding the password (or the empty state).
class _PasswordCard extends StatelessWidget {
  const _PasswordCard({required this.value});

  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = isCompact(context);

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
                'Nenhuma senha gerada ainda',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            // Long passwords wrap instead of shrinking: a 64-character one
            // scaled down to a single line would be unreadable on a phone.
            : SelectableText(
                value!,
                textAlign: TextAlign.center,
                style:
                    (compact
                            ? theme.textTheme.titleLarge
                            : theme.textTheme.headlineSmall)
                        ?.merge(monospaceFont),
              ),
      ),
    );
  }
}

/// Length, character classes and the special characters to use.
class _Options extends StatelessWidget {
  const _Options({
    required this.options,
    required this.onLengthChanged,
    required this.onCharsetToggled,
    required this.onSymbolToggled,
    required this.onSymbolsReset,
  });

  final PasswordOptions options;
  final ValueChanged<int> onLengthChanged;
  final void Function(PasswordCharset charset, bool enabled) onCharsetToggled;
  final void Function(String symbol, bool selected) onSymbolToggled;
  final VoidCallback onSymbolsReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // A Card (and not a plain Container) so the checkbox tiles and chips have
    // a Material ancestor to paint their ink on.
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
            _LengthField(length: options.length, onChanged: onLengthChanged),
            const SizedBox(height: 8),
            for (final charset in PasswordCharset.values)
              CheckboxListTile(
                value: options.includes(charset),
                // The last class left cannot be switched off: there would be
                // nothing to build the password from.
                onChanged: options.canDisable(charset)
                    ? (enabled) => onCharsetToggled(charset, enabled!)
                    : null,
                title: Text(charset.label),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            if (options.includes(PasswordCharset.symbols))
              _SymbolPicker(
                options: options,
                onToggled: onSymbolToggled,
                onReset: onSymbolsReset,
              ),
          ],
        ),
      ),
    );
  }
}

/// Slider plus -/+ buttons: the slider is quick, the buttons are exact.
class _LengthField extends StatelessWidget {
  const _LengthField({required this.length, required this.onChanged});

  final int length;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('Tamanho', style: theme.textTheme.titleSmall)),
            Text(
              '$length caracteres',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton.outlined(
              onPressed: length > PasswordOptions.minLength
                  ? () => onChanged(length - 1)
                  : null,
              tooltip: 'Diminuir',
              icon: const Icon(Icons.remove),
            ),
            Expanded(
              child: Slider(
                value: length.toDouble(),
                min: PasswordOptions.minLength.toDouble(),
                max: PasswordOptions.maxLength.toDouble(),
                divisions:
                    PasswordOptions.maxLength - PasswordOptions.minLength,
                label: '$length',
                onChanged: (value) => onChanged(value.round()),
              ),
            ),
            IconButton.outlined(
              onPressed: length < PasswordOptions.maxLength
                  ? () => onChanged(length + 1)
                  : null,
              tooltip: 'Aumentar',
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}

/// One chip per special character, selected ones included in the password.
class _SymbolPicker extends StatelessWidget {
  const _SymbolPicker({
    required this.options,
    required this.onToggled,
    required this.onReset,
  });

  final PasswordOptions options;
  final void Function(String symbol, bool selected) onToggled;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalog = PasswordCharset.symbols.chars.split('');

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${options.symbols.length} de ${catalog.length} '
                  'selecionados',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton(
                onPressed: options.symbols == PasswordOptions.defaultSymbols
                    ? null
                    : onReset,
                child: const Text('Restaurar padrão'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final symbol in catalog)
                FilterChip(
                  label: Text(symbol, style: monospaceFont),
                  selected: options.symbols.contains(symbol),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  onSelected: options.canDeselect(symbol)
                      ? (selected) => onToggled(symbol, selected)
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
