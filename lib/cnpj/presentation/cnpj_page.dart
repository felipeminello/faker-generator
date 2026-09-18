import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/presentation/generator_view.dart';
import '../bloc/cnpj_bloc.dart';

/// Presentation page for the CNPJ generator feature.
class CnpjPage extends StatelessWidget {
  const CnpjPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CnpjBloc, CnpjState>(
      builder: (context, state) {
        final value = switch (state) {
          CnpjInitial() => null,
          CnpjGenerated(:final cnpj) => cnpj.formatted,
        };

        return GeneratorView(
          title: 'CNPJ',
          description:
              'Cadastro Nacional da Pessoa Jurídica válido, com dígitos '
              'verificadores.',
          icon: Icons.business,
          value: value,
          onGenerate: () => context.read<CnpjBloc>().add(const CnpjRequested()),
          onClear: () => context.read<CnpjBloc>().add(const CnpjCleared()),
        );
      },
    );
  }
}
