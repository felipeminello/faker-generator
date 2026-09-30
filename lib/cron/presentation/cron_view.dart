import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/presentation/generator_actions.dart';
import '../../shared/presentation/monospace.dart';
import '../../shared/presentation/responsive.dart';
import '../data/cron_field.dart';
import '../data/cron_macro.dart';
import '../data/cron_model.dart';
import '../data/cron_schedule.dart';
import '../data/cron_text.dart';

/// Presentation widget for the cron editor.
///
/// Like `LoremView` it holds no business logic: `CronPage` passes the
/// expression and what it means, and receives the user's intent through
/// callbacks.
class CronView extends StatelessWidget {
  const CronView({
    super.key,
    required this.expression,
    required this.cron,
    required this.error,
    required this.activeField,
    required this.fieldSpans,
    required this.onExpressionChanged,
    required this.onCursorMoved,
    required this.onGenerate,
    required this.onClear,
    required this.onShowExamples,
  });

  /// The expression as typed.
  final String expression;

  /// The explained expression, when it is valid.
  final CronModel? cron;

  /// Why the expression is invalid, when it is.
  final CronFormatException? error;

  /// The field under the cursor, if any.
  final CronField? activeField;

  /// Where each field is written in [expression].
  final List<CronSpan> fieldSpans;

  final ValueChanged<String> onExpressionChanged;
  final ValueChanged<int?> onCursorMoved;
  final VoidCallback onGenerate;
  final VoidCallback onClear;
  final VoidCallback onShowExamples;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = expression.trim();
    final runs = cron?.nextRuns ?? const [];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Only the actions are pinned: with the next runs and the
              // reference the page is taller than a phone, so the rest
              // scrolls.
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 32,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Cron',
                              style: theme.textTheme.headlineSmall,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: onShowExamples,
                            icon: const Icon(Icons.lightbulb_outline),
                            label: const Text('Exemplos'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Editor de expressões cron, no estilo do '
                        'crontab.guru. Escreva uma, gere uma aleatória ou '
                        'parta de um exemplo.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _DescriptionCard(cron: cron, error: error),
                      const SizedBox(height: 20),
                      _Editor(
                        expression: expression,
                        error: error,
                        activeField: activeField,
                        fieldSpans: fieldSpans,
                        onChanged: onExpressionChanged,
                        onCursorMoved: onCursorMoved,
                      ),
                      if (runs.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _NextRuns(runs: runs),
                      ],
                      const SizedBox(height: 20),
                      _Reference(activeField: activeField),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GeneratorActions(
                value: value.isEmpty ? null : value,
                onGenerate: onGenerate,
                onClear: onClear,
                regenerateLabel: 'Gerar nova',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the expression means (or why it is invalid), and when it runs next.
class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.cron, required this.error});

  final CronModel? cron;
  final CronFormatException? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = isCompact(context);
    final cron = this.cron;
    final error = this.error;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final Widget content;
    if (cron != null) {
      final equivalent = cron.equivalent;
      content = Column(
        children: [
          Text(
            '“${cron.description}”',
            textAlign: TextAlign.center,
            style: compact
                ? theme.textTheme.titleLarge
                : theme.textTheme.headlineSmall,
          ),
          if (equivalent != null) ...[
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                text: 'o mesmo que ',
                children: [TextSpan(text: equivalent, style: monospaceFont)],
              ),
              style: muted,
            ),
          ],
          const SizedBox(height: 12),
          Text(
            _nextRunLine(cron),
            textAlign: TextAlign.center,
            style: cron.neverRuns
                ? muted?.copyWith(color: theme.colorScheme.error)
                : muted,
          ),
        ],
      );
    } else if (error != null) {
      content = Column(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(height: 8),
          Text(
            error.message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      );
    } else {
      content = Text(
        'Nenhuma expressão ainda',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 96),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 24,
        vertical: compact ? 20 : 28,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Center(child: content),
    );
  }

  static String _nextRunLine(CronModel cron) {
    if (cron.atReboot) return 'Roda uma vez, sempre que o sistema inicia.';
    if (cron.neverRuns) return 'Nunca roda: essa data não existe.';
    final next = cron.nextRuns.first;
    return 'próxima: ${_date(next)} às ${_clock(next)}';
  }
}

/// The expression field, plus one chip per field: the chip under the cursor
/// is highlighted, the one with an error is red, and tapping one selects
/// that field in the text.
class _Editor extends StatefulWidget {
  const _Editor({
    required this.expression,
    required this.error,
    required this.activeField,
    required this.fieldSpans,
    required this.onChanged,
    required this.onCursorMoved,
  });

  final String expression;
  final CronFormatException? error;
  final CronField? activeField;
  final List<CronSpan> fieldSpans;
  final ValueChanged<String> onChanged;
  final ValueChanged<int?> onCursorMoved;

  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.expression,
  );
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onEdited);
    _focusNode.addListener(_reportCursor);
  }

  @override
  void didUpdateWidget(_Editor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Examples, "Gerar" and "Limpar" replace the expression in the Bloc;
    // mirror them here. While typing, the two already agree.
    if (widget.expression != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.expression,
        selection: TextSelection.collapsed(offset: widget.expression.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Text first, then the cursor: the field under the cursor is looked up in
  /// the new text.
  void _onEdited() {
    if (_controller.text != widget.expression) {
      widget.onChanged(_controller.text);
    }
    _reportCursor();
  }

  void _reportCursor() {
    final selection = _controller.selection;
    widget.onCursorMoved(
      _focusNode.hasFocus && selection.isValid ? selection.start : null,
    );
  }

  /// Selects [field] in the text, or puts the cursor at the end when it has
  /// not been typed yet.
  void _select(CronField field) {
    final spans = widget.fieldSpans;
    _controller.selection = field.index < spans.length
        ? TextSelection(
            baseOffset: spans[field.index].start,
            extentOffset: spans[field.index].end,
          )
        : TextSelection.collapsed(offset: _controller.text.length);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final compact = isCompact(context);
    final errorField = widget.error?.field;
    final style =
        (compact ? theme.textTheme.titleLarge : theme.textTheme.headlineSmall)
            ?.merge(monospaceFont);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            textAlign: TextAlign.center,
            style: style,
            autocorrect: false,
            enableSuggestions: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            inputFormatters: const [_FieldSpacingFormatter()],
            decoration: InputDecoration(
              hintText: '5 4 * * *',
              hintStyle: style?.copyWith(color: colors.onSurfaceVariant),
              border: const OutlineInputBorder(),
              // Red border only: the message is in the card above.
              error: widget.error == null ? null : const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final field in CronField.values)
                ChoiceChip(
                  label: Text(field.label),
                  selected: widget.activeField == field,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  avatar: field == errorField
                      ? Icon(Icons.error_outline, color: colors.error)
                      : null,
                  side: field == errorField
                      ? BorderSide(color: colors.error)
                      : null,
                  onSelected: (_) => _select(field),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Types the space between two fields typed (or pasted) together, so they
/// are easy to tell apart: `*****` becomes `* * * * *`, `*/5*` becomes
/// `*/5 *`. Where a space belongs is [CronSchedule.missingSpaces]'s call.
class _FieldSpacingFormatter extends TextInputFormatter {
  const _FieldSpacingFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final source = newValue.text;
    final spaces = CronSchedule.missingSpaces(source);
    if (spaces.isEmpty) return newValue;

    final text = StringBuffer();
    var from = 0;
    for (final at in spaces) {
      text
        ..write(source.substring(from, at))
        ..write(' ');
      from = at;
    }
    text.write(source.substring(from));

    // A space inserted right at the cursor stays after it: typing "1" in
    // front of "*" gives "1| *", so the "5" typed next still makes "15".
    int shift(int offset) =>
        offset < 0 ? offset : offset + spaces.where((at) => at < offset).length;

    final selection = newValue.selection;
    final composing = newValue.composing;
    return TextEditingValue(
      text: text.toString(),
      selection: selection.copyWith(
        baseOffset: shift(selection.baseOffset),
        extentOffset: shift(selection.extentOffset),
      ),
      composing: composing.isValid
          ? TextRange(start: shift(composing.start), end: shift(composing.end))
          : composing,
    );
  }
}

/// The next runs, with weekday, date and time.
class _NextRuns extends StatelessWidget {
  const _NextRuns({required this.runs});

  final List<DateTime> runs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _Panel(
      title: 'Próximas execuções',
      trailing: 'horário local',
      child: Column(
        children: [
          for (final run in runs)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_date(run), style: theme.textTheme.bodyLarge),
                  ),
                  Text(
                    _clock(run),
                    style: theme.textTheme.bodyLarge?.merge(monospaceFont),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// crontab.guru's cheat sheet: the special characters, then the values the
/// field under the cursor accepts — or the `@` shortcuts, when no field is
/// being edited.
class _Reference extends StatelessWidget {
  const _Reference({required this.activeField});

  final CronField? activeField;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final field = activeField;

    final rows = <(String, String, String?)>[
      ('*', 'qualquer valor', null),
      (',', 'separador de lista de valores', null),
      ('-', 'intervalo de valores', null),
      ('/', 'incremento: “a cada N”', null),
      if (field != null) ...[
        (field.allowedValues, 'valores permitidos', null),
        if (field.names.isNotEmpty)
          (
            '${field.names.first}-${field.names.last}',
            'nomes em inglês, no lugar dos números',
            null,
          ),
        if (field == CronField.dayOfWeek) ('7', 'domingo (não padrão)', null),
      ] else
        for (final macro in CronMacro.values)
          macro.expression == null
              ? (macro.keyword, 'ao reiniciar o sistema', null)
              : (macro.keyword, 'o mesmo que ', macro.expression),
    ];

    return _Panel(
      title: field == null ? 'Referência' : 'Referência · ${field.label}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Table(
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              for (final (symbol, meaning, code) in rows)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 4, 16, 4),
                      child: Text(
                        symbol,
                        style: theme.textTheme.bodyLarge
                            ?.merge(monospaceFont)
                            .copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text.rich(
                        TextSpan(
                          text: meaning,
                          children: [
                            if (code != null)
                              TextSpan(text: code, style: monospaceFont),
                          ],
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (field == null) ...[
            const SizedBox(height: 8),
            Text(
              'Os atalhos com @ não são padrão: a maioria dos crons aceita, '
              'mas não todos. Toque num campo para ver os valores dele.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Outlined card shared by the editor, the next runs and the reference.
class _Panel extends StatelessWidget {
  const _Panel({this.title, this.trailing, required this.child});

  final String? title;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = this.title;
    final trailing = this.trailing;

    // A Card (and not a plain Container) so the chips have a Material
    // ancestor to paint their ink on.
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact(context) ? 12 : 20,
          vertical: 16,
        ),
        child: title == null
            ? child
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title, style: theme.textTheme.titleSmall),
                      ),
                      if (trailing != null)
                        Text(
                          trailing,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  child,
                ],
              ),
      ),
    );
  }
}

/// `DateTime.weekday` order: Monday is 1.
const _weekdayAbbreviations = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

/// "qua, 30/09/2026".
String _date(DateTime time) =>
    '${_weekdayAbbreviations[time.weekday - 1]}, '
    '${twoDigits(time.day)}/${twoDigits(time.month)}/${time.year}';

/// "04:05".
String _clock(DateTime time) =>
    '${twoDigits(time.hour)}:${twoDigits(time.minute)}';
