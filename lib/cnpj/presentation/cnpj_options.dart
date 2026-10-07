import 'package:flutter/material.dart';

import '../../shared/presentation/count_field.dart';
import '../data/cnpj_kind.dart';
import '../data/cnpj_repository.dart';

/// Format, amount, head office or branch, and punctuation of the CNPJs to
/// generate.
class CnpjOptions extends StatelessWidget {
  const CnpjOptions({
    super.key,
    required this.count,
    required this.kind,
    required this.headOffice,
    required this.masked,
    required this.onCountChanged,
    required this.onKindChanged,
    required this.onHeadOfficeToggled,
    required this.onMaskToggled,
  });

  final int count;
  final CnpjKind kind;
  final bool headOffice;
  final bool masked;
  final ValueChanged<int> onCountChanged;
  final ValueChanged<CnpjKind> onKindChanged;
  final ValueChanged<bool> onHeadOfficeToggled;
  final ValueChanged<bool> onMaskToggled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final example = switch ((kind, headOffice)) {
      (CnpjKind.numeric, true) => '11.222.333/0001-81',
      (CnpjKind.numeric, false) => '11.222.333/0002-62',
      (CnpjKind.alphanumeric, true) => '12.ABC.345/0001-88',
      (CnpjKind.alphanumeric, false) => '12.ABC.345/01DE-35',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<CnpjKind>(
          segments: [
            for (final value in CnpjKind.values)
              ButtonSegment(value: value, label: Text(value.label)),
          ],
          selected: {kind},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => onKindChanged(selection.first),
        ),
        const SizedBox(height: 8),
        Text(
          switch (kind) {
            CnpjKind.numeric => 'O formato clássico, só com números.',
            CnpjKind.alphanumeric =>
              'O novo formato da Receita Federal, emitido desde julho de '
                  '2026: letras e números nos 12 primeiros caracteres.',
          },
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        CountField(
          label: 'Quantidade de CNPJs',
          count: count,
          min: 1,
          max: CnpjRepository.maxCount,
          onChanged: onCountChanged,
        ),
        const SizedBox(height: 4),
        SwitchListTile(
          value: headOffice,
          onChanged: onHeadOfficeToggled,
          contentPadding: EdgeInsets.zero,
          title: const Text('Matriz'),
          subtitle: Text(
            headOffice
                ? 'Ordem 0001, a da sede da empresa'
                : 'Filiais, com número de ordem aleatório',
          ),
        ),
        SwitchListTile(
          value: masked,
          onChanged: onMaskToggled,
          contentPadding: EdgeInsets.zero,
          title: const Text('Com pontuação'),
          subtitle: Text(
            masked ? example : example.replaceAll(RegExp('[./-]'), ''),
          ),
        ),
      ],
    );
  }
}
