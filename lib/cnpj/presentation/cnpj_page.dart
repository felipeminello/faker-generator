import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/presentation/export_button.dart';
import '../../shared/presentation/list_generator_view.dart';
import '../bloc/cnpj_bloc.dart';
import 'cnpj_options.dart';

/// Presentation page for the CNPJ generator feature.
class CnpjPage extends StatelessWidget {
  const CnpjPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<CnpjBloc, CnpjState>(
      listenWhen: (previous, current) => previous.export != current.export,
      listener: (context, state) =>
          showExportResult(context, state.export, state.savedTo),
      child: BlocBuilder<CnpjBloc, CnpjState>(
        builder: (context, state) {
          final bloc = context.read<CnpjBloc>();

          return ListGeneratorView(
            title: 'CNPJ',
            description:
                'Cadastro Nacional da Pessoa Jurídica válido, com dígitos '
                'verificadores, no formato numérico ou no novo alfanumérico '
                'da Receita Federal. Gere um ou uma lista sem repetições e '
                'exporte para usar nos seus testes.',
            icon: Icons.business,
            options: CnpjOptions(
              count: state.count,
              kind: state.kind,
              headOffice: state.headOffice,
              masked: state.masked,
              onCountChanged: (count) => bloc.add(CnpjCountChanged(count)),
              onKindChanged: (kind) => bloc.add(CnpjKindChanged(kind)),
              onHeadOfficeToggled: (headOffice) =>
                  bloc.add(CnpjHeadOfficeToggled(headOffice)),
              onMaskToggled: (masked) => bloc.add(CnpjMaskToggled(masked)),
            ),
            values: state.values,
            regenerateLabel: state.count == 1 ? 'Gerar novo' : 'Gerar novos',
            onGenerate: () => bloc.add(const CnpjRequested()),
            onClear: () => bloc.add(const CnpjCleared()),
            onExport: state.canExport
                ? (format) => bloc.add(CnpjExportRequested(format))
                : null,
          );
        },
      ),
    );
  }
}
