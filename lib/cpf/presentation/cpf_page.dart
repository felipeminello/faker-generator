import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/presentation/generator_view.dart';
import '../bloc/cpf_bloc.dart';

/// Presentation page for the CPF generator feature.
class CpfPage extends StatelessWidget {
  const CpfPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CpfBloc, CpfState>(
      builder: (context, state) {
        final value = switch (state) {
          CpfInitial() => null,
          CpfGenerated(:final cpf) => cpf.formatted,
        };

        return GeneratorView(
          title: 'CPF',
          description:
              'Cadastro de Pessoa Física válido, com dígitos verificadores.',
          icon: Icons.badge,
          value: value,
          onGenerate: () => context.read<CpfBloc>().add(const CpfRequested()),
          onClear: () => context.read<CpfBloc>().add(const CpfCleared()),
        );
      },
    );
  }
}
