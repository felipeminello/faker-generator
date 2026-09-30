import 'package:flutter/painting.dart';

/// Monospace style for passwords and cron expressions, where telling
/// `l`/`I`/`1` and `O`/`0` apart (or seeing each field line up) matters.
/// `monospace` is an alias only Android and Linux resolve; the fallbacks
/// cover Apple platforms (Menlo) and Windows (Consolas).
const monospaceFont = TextStyle(
  fontFamily: 'monospace',
  fontFamilyFallback: ['Menlo', 'Consolas'],
);
