import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:transito/models/app/app_colors.dart';

class NativeGlassButton extends StatelessWidget {
  final String iconName;
  final VoidCallback onPressed;

  const NativeGlassButton({
    super.key,
    required this.iconName,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    AppColors appColors = context.watch<AppColors>();

    return SizedBox(
      width: 56.0,
      height: 56.0,
      child: UiKitView(
        viewType: 'GlassButton',
        layoutDirection: TextDirection.ltr,
        creationParams: {
          'icon': iconName,
          'tintColor': appColors.scheme.primaryContainer.toARGB32(),
          'iconColor': appColors.scheme.onPrimaryContainer.toARGB32(),
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (int id) {
          final channel = MethodChannel('transito/glass_button_$id');
          channel.setMethodCallHandler((call) async {
            if (call.method == 'onPressed') {
              onPressed();
            }
          });
        },
      ),
    );
  }
}
