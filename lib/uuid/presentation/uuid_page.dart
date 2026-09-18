import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/presentation/generator_view.dart';
import '../bloc/uuid_bloc.dart';

/// Presentation page for the UUID v4 generator feature.
class UuidPage extends StatelessWidget {
  const UuidPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UuidBloc, UuidState>(
      builder: (context, state) {
        final value = switch (state) {
          UuidInitial() => null,
          UuidGenerated(:final uuid) => uuid.value,
        };

        return GeneratorView(
          title: 'UUID v4',
          description:
              'Identificador único universal aleatório (RFC 4122, versão 4).',
          icon: Icons.fingerprint,
          value: value,
          onGenerate: () => context.read<UuidBloc>().add(const UuidRequested()),
          onClear: () => context.read<UuidBloc>().add(const UuidCleared()),
        );
      },
    );
  }
}
