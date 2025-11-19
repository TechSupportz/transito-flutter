import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NativeTabBarItem {
  final String label;
  final String symbol;

  const NativeTabBarItem({
    required this.label,
    required this.symbol,
  });
}

class NativeTabBar extends StatefulWidget {
  final List<NativeTabBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color tintColor;
  final bool split;
  final int rightCount;

  const NativeTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.tintColor,
    this.split = false,
    this.rightCount = 1,
  });

  @override
  State<NativeTabBar> createState() => _NativeTabBarState();
}

class _NativeTabBarState extends State<NativeTabBar> {
  MethodChannel? _channel;

  @override
  void didUpdateWidget(NativeTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateNativeView();
  }

  void _updateNativeView() {
    if (_channel != null) {
      _channel!.invokeMethod('update', _createParams());
    }
  }

  Map<String, dynamic> _createParams() {
    return {
      'labels': widget.items.map((e) => e.label).toList(),
      'symbols': widget.items.map((e) => e.symbol).toList(),
      'selectedIndex': widget.currentIndex,
      'split': widget.split,
      'rightCount': widget.rightCount,
      'isDark': Theme.of(context).brightness == Brightness.dark,
      'tintColor': widget.tintColor.toARGB32(),
    };
  }

  @override
  Widget build(BuildContext context) {
    // This is an iOS-only view
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return const SizedBox.shrink();
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    // Standard tab bar height is 49. Add bottom padding for safe area.
    final height = 49.0 + bottomPadding;

    return SizedBox(
      height: height,
      child: UiKitView(
        viewType: 'NativeTabBar',
        creationParams: _createParams(),
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (id) {
          _channel = MethodChannel('NativeTabBar_$id');
          _channel!.setMethodCallHandler((call) async {
            if (call.method == 'valueChanged') {
              final index = call.arguments['index'] as int;
              widget.onTap(index);
            }
          });
        },
      ),
    );
  }
}
