import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Numeric amount field with -/+ steppers, kept in sync with the amount held
/// by a Bloc.
class CountField extends StatefulWidget {
  const CountField({
    super.key,
    required this.label,
    required this.count,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  /// Field label, such as "Quantidade de CPFs".
  final String label;

  final int count;
  final int min;
  final int max;

  /// Receives what is typed as is; the Bloc clamps it to [min]..[max].
  final ValueChanged<int> onChanged;

  @override
  State<CountField> createState() => _CountFieldState();
}

class _CountFieldState extends State<CountField> {
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.count}',
  );

  @override
  void didUpdateWidget(CountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The Bloc clamps the amount (and the Lorem one resets it on unit
    // changes); mirror that here without fighting the user while they are
    // typing.
    if (widget.count != int.tryParse(_controller.text)) {
      _controller.text = '${widget.count}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _step(int delta) {
    final next = (widget.count + delta).clamp(widget.min, widget.max);
    _controller.text = '$next';
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: widget.label,
              helperText: 'de ${widget.min} a ${widget.max}',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed != null) widget.onChanged(parsed);
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          onPressed: widget.count > widget.min ? () => _step(-1) : null,
          tooltip: 'Diminuir',
          icon: const Icon(Icons.remove),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          onPressed: widget.count < widget.max ? () => _step(1) : null,
          tooltip: 'Aumentar',
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
