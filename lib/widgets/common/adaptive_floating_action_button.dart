import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/common_provider.dart';
import 'package:transito/widgets/common/app_symbol.dart';
import 'package:transito/widgets/liquid_glass/native_glass_button.dart';

class AdaptiveFloatingActionButton extends StatelessWidget {
  const AdaptiveFloatingActionButton({
    super.key,
    required this.materialSymbol,
    required this.cupertinoSymbolString,
    required this.onPressed,
  });
  final IconData materialSymbol;
  final String cupertinoSymbolString;
  final void Function() onPressed;

  static FloatingActionButtonLocation locationOf(BuildContext context) {
    return context.watch<CommonProvider>().supportsLiquidGlass
        ? const _LiquidGlassFabLocation()
        : FloatingActionButtonLocation.endFloat;
  }

  @override
  Widget build(BuildContext context) {
    bool supportsLiquidGlass = context.watch<CommonProvider>().supportsLiquidGlass;

    if (supportsLiquidGlass) {
      return NativeGlassButton(
        iconName: cupertinoSymbolString,
        onPressed: () {
          onPressed();
          HapticFeedback.selectionClick();
        },
      );
    } else {
      return FloatingActionButton(
        onPressed: () {
          onPressed();
          HapticFeedback.selectionClick();
        },
        enableFeedback: true,
        child: AppSymbol(materialSymbol),
      );
    }
  }
}

class _LiquidGlassFabLocation extends FloatingActionButtonLocation {
  const _LiquidGlassFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final Offset floatingOffset = FloatingActionButtonLocation.endFloat.getOffset(scaffoldGeometry);

    // Match the native tab bar's 20-point side inset. Its 64-point action
    // extends 14 points into the bottom safe area on home-indicator iPhones.
    const double sideInset = 20;
    final double bottomInset = math.max(8, scaffoldGeometry.minViewPadding.bottom - 14);
    double y =
        scaffoldGeometry.scaffoldSize.height -
        bottomInset -
        scaffoldGeometry.floatingActionButtonSize.height;

    // Keep Scaffold's avoidance of keyboards, bottom bars, sheets and snackbars.
    if (scaffoldGeometry.contentBottom <
            scaffoldGeometry.scaffoldSize.height - scaffoldGeometry.minViewPadding.bottom ||
        scaffoldGeometry.bottomSheetSize.height > 0 ||
        scaffoldGeometry.snackBarSize.height > 0) {
      y = math.min(y, floatingOffset.dy);
    }

    final double xAdjustment = switch (scaffoldGeometry.textDirection) {
      TextDirection.ltr => kFloatingActionButtonMargin - sideInset,
      TextDirection.rtl => sideInset - kFloatingActionButtonMargin,
    };
    return Offset(floatingOffset.dx + xAdjustment, y);
  }
}
