import 'package:cupertino_native/components/button.dart';
import 'package:cupertino_native/style/button_style.dart';
import 'package:cupertino_native/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/common_provider.dart';
import 'package:transito/widgets/common/app_symbol.dart';

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
      return CNButton.icon(
        onPressed: () {
          onPressed();
          HapticFeedback.selectionClick();
        },
        icon: CNSymbol(
          cupertinoSymbolString,
          size: 16,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        tint: Theme.of(context).colorScheme.primaryContainer,
        size: 56,
        style: CNButtonStyle.prominentGlass,
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
