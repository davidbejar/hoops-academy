/// The design system's tokens (ADR-0040). Import this one file:
/// `import 'package:hoops_app/core/design/tokens.dart';`
library;

import 'package:flutter/material.dart';

import 'colors.dart';

export 'colors.dart';
export 'contrast.dart';
export 'metrics.dart';
export 'tone.dart';
export 'typography.dart';

/// Entry point to the tokens from a widget: `HoopsTokens.colorsOf(context)`.
/// Spacing, radii, sizes, elevation and motion are constants:
/// [HoopsSpace], [HoopsRadius], [HoopsSize], [HoopsElevation], [HoopsMotion],
/// widths in [WidthClass], type in [HoopsType].
abstract final class HoopsTokens {
  /// The colours of the current theme (falls back to the brightness when the
  /// theme was not built by `buildTheme`, e.g. in an isolated widget test).
  static HoopsColors colorsOf(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<HoopsColors>() ?? HoopsColors.of(theme.brightness);
  }
}
