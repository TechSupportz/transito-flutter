import 'package:flutter/material.dart';

void scrollToSelectedContent(GlobalKey expansionTileKey) {
  final keyContext = expansionTileKey.currentContext;
  if (keyContext != null) {
    Future.delayed(const Duration(milliseconds: 200)).then((value) {
      Scrollable.ensureVisible(keyContext,
          curve: Curves.easeInOut, duration: const Duration(milliseconds: 250));
    });
  }
}
