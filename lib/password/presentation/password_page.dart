import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/password_bloc.dart';
import 'password_view.dart';
import 'recent_passwords.dart';

/// Presentation page for the password generator feature.
class PasswordPage extends StatelessWidget {
  const PasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PasswordBloc, PasswordState>(
      builder: (context, state) {
        final bloc = context.read<PasswordBloc>();

        return PasswordView(
          options: state.options,
          password: state.password,
          onLengthChanged: (length) => bloc.add(PasswordLengthChanged(length)),
          onCharsetToggled: (charset, enabled) =>
              bloc.add(PasswordCharsetToggled(charset, enabled)),
          onSymbolToggled: (symbol, selected) =>
              bloc.add(PasswordSymbolToggled(symbol, selected)),
          onSymbolsReset: () => bloc.add(const PasswordSymbolsReset()),
          onGenerate: () => bloc.add(const PasswordRequested()),
          onCopied: () => bloc.add(const PasswordCopied()),
          onClear: () => bloc.add(const PasswordCleared()),
          onShowRecent: () => showRecentPasswords(context),
        );
      },
    );
  }
}
