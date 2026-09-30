import 'package:flutter/material.dart';

import '../../shared/presentation/monospace.dart';
import '../../shared/presentation/responsive.dart';
import '../data/cron_example.dart';

/// Lists common expressions, like crontab.guru's examples page: in a bottom
/// sheet on phones, in a dialog on wider windows.
///
/// Returns the expression picked, or `null` when the list was dismissed.
Future<String?> showCronExamples(BuildContext context) {
  Widget list(BuildContext _) => const _CronExamples();

  return isCompact(context)
      ? showModalBottomSheet<String>(
          context: context,
          builder: list,
          showDragHandle: true,
          isScrollControlled: true,
          useSafeArea: true,
        )
      : showDialog<String>(
          context: context,
          builder: (context) => Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: list(context),
            ),
          ),
        );
}

class _CronExamples extends StatelessWidget {
  const _CronExamples();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(top: isCompact(context) ? 0 : 16, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('Exemplos', style: theme.textTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Expressões comuns. Toque em uma para usá-la no editor.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: cronExamples.length,
              itemBuilder: (context, index) {
                final example = cronExamples[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  title: Text(example.label),
                  subtitle: Text(example.expression, style: monospaceFont),
                  onTap: () => Navigator.pop(context, example.expression),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
