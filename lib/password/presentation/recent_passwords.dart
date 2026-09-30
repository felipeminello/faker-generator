import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/presentation/copy_to_clipboard.dart';
import '../../shared/presentation/monospace.dart';
import '../../shared/presentation/responsive.dart';
import '../bloc/password_bloc.dart';
import '../data/password_history_repository.dart';
import '../data/password_model.dart';

/// Lists the recent passwords: in a bottom sheet on phones, in a dialog on
/// wider windows. Picking one copies it to the clipboard.
Future<void> showRecentPasswords(BuildContext context) async {
  final bloc = context.read<PasswordBloc>();
  Widget list(BuildContext _) =>
      BlocProvider.value(value: bloc, child: const _RecentPasswords());

  final picked = isCompact(context)
      ? await showModalBottomSheet<String>(
          context: context,
          builder: list,
          showDragHandle: true,
          isScrollControlled: true,
          useSafeArea: true,
        )
      : await showDialog<String>(
          context: context,
          builder: (context) => Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: list(context),
            ),
          ),
        );

  // Copied once the list is closed: a snack bar shown while it is open would
  // be hidden behind it.
  if (picked != null && context.mounted) await copyToClipboard(context, picked);
}

class _RecentPasswords extends StatelessWidget {
  const _RecentPasswords();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<PasswordBloc, PasswordState>(
      buildWhen: (previous, current) => previous.recent != current.recent,
      builder: (context, state) {
        final recent = state.recent;

        return Padding(
          padding: EdgeInsets.only(top: isCompact(context) ? 0 : 16, bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Senhas recentes',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: recent.isEmpty
                          ? null
                          : () => context.read<PasswordBloc>().add(
                              const PasswordHistoryCleared(),
                            ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Limpar'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'As ${PasswordHistoryRepository.capacity} últimas senhas '
                  'geradas. Toque em uma para copiar.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (recent.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'Nenhuma senha gerada ainda',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: recent.length,
                    itemBuilder: (context, index) =>
                        _RecentTile(password: recent[index]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.password});

  final PasswordModel password;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void pick() => Navigator.pop(context, password.value);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(
        password.value,
        style: theme.textTheme.bodyLarge?.merge(monospaceFont),
      ),
      subtitle: Text(
        '${password.length} caracteres · ${_when(password.createdAt)}',
      ),
      trailing: IconButton(
        onPressed: pick,
        tooltip: 'Copiar',
        icon: const Icon(Icons.copy),
      ),
      onTap: pick,
    );
  }
}

/// "hoje, 14:05", "03/09, 14:05" or, for another year, "03/09/2025, 14:05".
String _when(DateTime time) {
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');

  final clock = '${two(time.hour)}:${two(time.minute)}';
  if (time.year == now.year && time.month == now.month && time.day == now.day) {
    return 'hoje, $clock';
  }
  final date = '${two(time.day)}/${two(time.month)}';
  return time.year == now.year ? '$date, $clock' : '$date/${time.year}, $clock';
}
