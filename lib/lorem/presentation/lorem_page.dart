import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/lorem_bloc.dart';
import 'lorem_view.dart';

/// Presentation page for the Lorem Ipsum generator feature.
class LoremPage extends StatelessWidget {
  const LoremPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoremBloc, LoremState>(
      builder: (context, state) {
        final bloc = context.read<LoremBloc>();

        return LoremView(
          unit: state.unit,
          count: state.count,
          startWithLorem: state.startWithLorem,
          lorem: state.lorem,
          onUnitChanged: (unit) => bloc.add(LoremUnitChanged(unit)),
          onCountChanged: (count) => bloc.add(LoremCountChanged(count)),
          onOpeningToggled: (value) => bloc.add(LoremOpeningToggled(value)),
          onGenerate: () => bloc.add(const LoremRequested()),
          onClear: () => bloc.add(const LoremCleared()),
        );
      },
    );
  }
}
