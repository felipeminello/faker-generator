import 'package:flutter/material.dart';

/// Width below which the layout switches to its phone-friendly variant:
/// bottom navigation instead of a side rail, tighter padding and stacked
/// action buttons.
///
/// 600 is the Material 3 "compact" window-size breakpoint.
const double kCompactWidth = 600;

/// Whether the current window is narrow enough to need the compact layout.
bool isCompact(BuildContext context) =>
    MediaQuery.sizeOf(context).width < kCompactWidth;

/// Page padding: roomy on desktop, tight on phones where every pixel of
/// horizontal space counts.
EdgeInsets pagePadding(BuildContext context) => isCompact(context)
    ? const EdgeInsets.fromLTRB(16, 16, 16, 8)
    : const EdgeInsets.all(32);
