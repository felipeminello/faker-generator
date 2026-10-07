import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/validator_bloc.dart';
import 'validator_view.dart';

/// Presentation page for the CPF and CNPJ validator.
class ValidatorPage extends StatelessWidget {
  const ValidatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ValidatorBloc, ValidatorState>(
      builder: (context, state) {
        final bloc = context.read<ValidatorBloc>();

        return ValidatorView(
          text: state.text,
          results: state.results,
          validCount: state.validCount,
          invalidCount: state.invalidCount,
          onTextChanged: (text) => bloc.add(ValidatorTextChanged(text)),
          onExample: () => bloc.add(const ValidatorExampleRequested()),
          onClear: () => bloc.add(const ValidatorCleared()),
        );
      },
    );
  }
}
