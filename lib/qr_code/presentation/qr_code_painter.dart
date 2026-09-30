import 'package:flutter/rendering.dart';

import '../data/qr_code_model.dart';

/// Paints [qrCode] black on white, with the 4-module quiet zone the standard
/// asks for around it.
///
/// The colors are fixed rather than taken from the theme: scanners expect
/// dark modules on a light background.
class QrCodePainter extends CustomPainter {
  const QrCodePainter(this.qrCode);

  final QrCodeModel qrCode;

  /// Blank modules on each side of the code.
  static const quietZone = 4;

  static const _light = Color(0xFFFFFFFF);
  static const _dark = Color(0xFF000000);

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final count = qrCode.size;
    final module = side / (count + 2 * quietZone);
    final origin = Offset(
      (size.width - side) / 2 + quietZone * module,
      (size.height - side) / 2 + quietZone * module,
    );

    canvas.drawRect(Offset.zero & size, Paint()..color = _light);

    // Anti-aliasing would leave faint seams between neighbouring modules.
    final dark = Paint()
      ..color = _dark
      ..isAntiAlias = false;

    // One rectangle per run of dark modules in a row, rather than one per
    // module: version 40 has 31 329 of them.
    for (var row = 0; row < count; row++) {
      var column = 0;
      while (column < count) {
        if (!qrCode.isDark(row, column)) {
          column++;
          continue;
        }
        final start = column;
        while (column < count && qrCode.isDark(row, column)) {
          column++;
        }
        canvas.drawRect(
          Rect.fromLTRB(
            origin.dx + start * module,
            origin.dy + row * module,
            origin.dx + column * module,
            origin.dy + (row + 1) * module,
          ),
          dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(QrCodePainter oldDelegate) => oldDelegate.qrCode != qrCode;
}
