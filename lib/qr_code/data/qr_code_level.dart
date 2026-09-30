import 'package:qr/qr.dart';

/// QR Code error correction levels, from the least to the most redundant.
///
/// A higher level survives more damage (a smudge, a logo on top) at the cost
/// of a bigger code, and lowers how much text fits.
enum QrCodeLevel {
  low('L', 7, 2953, QrErrorCorrectLevel.low),
  medium('M', 15, 2331, QrErrorCorrectLevel.medium),
  quartile('Q', 25, 1663, QrErrorCorrectLevel.quartile),
  high('H', 30, 1273, QrErrorCorrectLevel.high);

  const QrCodeLevel(this.label, this.recovery, this.maxBytes, this.qrLevel);

  /// The letter the QR Code standard uses for the level.
  final String label;

  /// Roughly how much of the code (in %) can be damaged and still be read.
  final int recovery;

  /// How many bytes of arbitrary text fit in the largest code (version 40).
  /// Digits-only and upper-case text are packed tighter and fit more.
  final int maxBytes;

  /// The matching level of the `qr` package, which does the encoding.
  final QrErrorCorrectLevel qrLevel;
}
