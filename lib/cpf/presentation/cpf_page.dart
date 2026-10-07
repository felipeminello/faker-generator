import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/presentation/export_button.dart';
import '../../shared/presentation/list_generator_view.dart';
import '../bloc/cpf_bloc.dart';
import 'cpf_options.dart';

/// Presentation page for the CPF generator feature.
class CpfPage extends StatelessWidget {
  const CpfPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<CpfBloc, CpfState>(
      listenWhen: (previous, current) => previous.export != current.export,
      listener: (context, state) =>
          showExportResult(context, state.export, state.savedTo),
      child: BlocBuilder<CpfBloc, CpfState>(
        builder: (context, state) {
          final bloc = context.read<CpfBloc>();

          return ListGeneratorView(
            title: 'CPF',
            description:
                'Cadastro de Pessoa Física válido, com dígitos '
                'verificadores. Gere um ou uma lista sem repetições, de '
                'qualquer estado ou de um específico, e exporte para usar '
                'nos seus testes.',
            icon: Icons.badge,
            options: CpfOptions(
              count: state.count,
              uf: state.uf,
              masked: state.masked,
              onCountChanged: (count) => bloc.add(CpfCountChanged(count)),
              onUfChanged: (uf) => bloc.add(CpfUfChanged(uf)),
              onMaskToggled: (masked) => bloc.add(CpfMaskToggled(masked)),
            ),
            values: state.values,
            regenerateLabel: state.count == 1 ? 'Gerar novo' : 'Gerar novos',
            onGenerate: () => bloc.add(const CpfRequested()),
            onClear: () => bloc.add(const CpfCleared()),
            onExport: state.canExport
                ? (format) => bloc.add(CpfExportRequested(format))
                : null,
          );
        },
      ),
    );
  }
}
