import 'package:flutter/material.dart';

import '../../shared/presentation/count_field.dart';
import '../data/cpf_repository.dart';
import '../data/uf.dart';

/// Amount, unit of the federation and punctuation of the CPFs to generate.
class CpfOptions extends StatelessWidget {
  const CpfOptions({
    super.key,
    required this.count,
    required this.uf,
    required this.masked,
    required this.onCountChanged,
    required this.onUfChanged,
    required this.onMaskToggled,
  });

  final int count;

  /// `null` for any unit of the federation.
  final Uf? uf;

  final bool masked;
  final ValueChanged<int> onCountChanged;
  final ValueChanged<Uf?> onUfChanged;
  final ValueChanged<bool> onMaskToggled;

  @override
  Widget build(BuildContext context) {
    final uf = this.uf;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CountField(
          label: 'Quantidade de CPFs',
          count: count,
          min: 1,
          max: CpfRepository.maxCount,
          onChanged: onCountChanged,
        ),
        const SizedBox(height: 16),
        InputDecorator(
          decoration: InputDecoration(
            labelText: 'Estado de emissão',
            helperText: uf == null
                ? 'O 9º dígito do CPF indica a região fiscal onde foi emitido'
                : '9º dígito ${uf.fiscalRegion}: região fiscal de '
                      '${Uf.describeRegion(uf.fiscalRegion)}',
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Uf?>(
              value: uf,
              isDense: true,
              isExpanded: true,
              items: [
                const DropdownMenuItem(child: Text('Qualquer estado')),
                for (final value in Uf.values)
                  DropdownMenuItem(
                    value: value,
                    child: Text('${value.code} · ${value.fullName}'),
                  ),
              ],
              onChanged: onUfChanged,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SwitchListTile(
          value: masked,
          onChanged: onMaskToggled,
          contentPadding: EdgeInsets.zero,
          title: const Text('Com pontuação'),
          subtitle: Text(masked ? '123.456.789-09' : '12345678909'),
        ),
      ],
    );
  }
}
