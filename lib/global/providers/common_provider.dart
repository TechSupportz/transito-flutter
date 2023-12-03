import 'package:flutter/material.dart';

class CommonProvider extends ChangeNotifier {
  final bool isTablet = MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.views.single).size.shortestSide > 600;
}
