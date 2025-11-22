import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/common_provider.dart';
import 'package:transito/widgets/common/app_symbol.dart';
import 'package:transito/widgets/liquid_glass/native_glass_button.dart';

class AdaptiveFloatingActionButton extends StatelessWidget {
  const AdaptiveFloatingActionButton(
      {super.key,
      required this.materialSymbol,
      required this.cupertinoSymbolString,
      required this.onPressed});
  final IconData materialSymbol;
  final String cupertinoSymbolString;
  final void Function() onPressed;

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
