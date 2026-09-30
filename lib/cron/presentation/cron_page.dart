import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cron_bloc.dart';
import 'cron_examples.dart';
import 'cron_view.dart';

/// Presentation page for the cron editor feature.
class CronPage extends StatefulWidget {
  const CronPage({super.key});

  @override
  State<CronPage> createState() => _CronPageState();
}

class _CronPageState extends State<CronPage> {
  @override
  void initState() {
    super.initState();
    // The Bloc outlives the page: runs computed before the user switched
    // tabs may be in the past by now.
    context.read<CronBloc>().add(const CronRefreshed());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CronBloc, CronState>(
      builder: (context, state) {
        final bloc = context.read<CronBloc>();

        return CronView(
          expression: state.expression,
          cron: state.cron,
          error: state.error,
          activeField: state.activeField,
          fieldSpans: state.fieldSpans,
          onExpressionChanged: (expression) =>
              bloc.add(CronExpressionChanged(expression)),
          onCursorMoved: (offset) => bloc.add(CronCursorMoved(offset)),
          onGenerate: () => bloc.add(const CronRequested()),
          onClear: () => bloc.add(const CronCleared()),
          onShowExamples: () async {
            final picked = await showCronExamples(context);
            if (picked != null) bloc.add(CronExpressionChanged(picked));
          },
        );
      },
    );
  }
}
