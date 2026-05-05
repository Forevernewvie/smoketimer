import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smoke_timer/widgets/pen_design_widgets.dart';

void main() {
  test('warm timer palette keeps text and action contrast readable', () {
    expect(
      _contrast(SmokeUiTheme.light.textPrimary, SmokeUiTheme.light.background),
      greaterThanOrEqualTo(7),
    );
    expect(
      _contrast(
        SmokeUiTheme.light.textSecondary,
        SmokeUiTheme.light.background,
      ),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(SmokeUiTheme.dark.textPrimary, SmokeUiTheme.dark.background),
      greaterThanOrEqualTo(7),
    );
    expect(
      _contrast(SmokeUiTheme.dark.textSecondary, SmokeUiTheme.dark.background),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(Colors.black, SmokeUiPalette.accent),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(SmokeUiPalette.accentDark, SmokeUiPalette.accentSoft),
      greaterThanOrEqualTo(4.5),
    );
  });
}

double _contrast(Color foreground, Color background) {
  final foregroundLum = foreground.computeLuminance();
  final backgroundLum = background.computeLuminance();
  final lighter = foregroundLum > backgroundLum ? foregroundLum : backgroundLum;
  final darker = foregroundLum > backgroundLum ? backgroundLum : foregroundLum;
  return (lighter + 0.05) / (darker + 0.05);
}
