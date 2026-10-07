import 'package:flutter/material.dart';

/// Width below which the layout switches to its phone-friendly variant:
/// bottom navigation instead of a side rail, tighter padding and stacked
/// action buttons.
///
/// 600 is the Material 3 "compact" window-size breakpoint.
const double kCompactWidth = 600;

/// Width from which the navigation lists every tool by section in a side
/// panel, instead of a [NavigationRail] of icons.
///
/// 840 is the Material 3 "expanded" window-size breakpoint.
const double kExpandedWidth = 840;

/// Whether the current window is narrow enough to need the compact layout.
bool isCompact(BuildContext context) =>
    MediaQuery.sizeOf(context).width < kCompactWidth;

/// Whether the current window is wide enough for the side panel.
bool isExpanded(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kExpandedWidth;

/// Page padding: roomy on desktop, tight on phones where every pixel of
/// horizontal space counts.
EdgeInsets pagePadding(BuildContext context) => isCompact(context)
    ? const EdgeInsets.fromLTRB(16, 16, 16, 8)
    : const EdgeInsets.all(32);
