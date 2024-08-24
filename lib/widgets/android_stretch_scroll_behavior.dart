import 'package:flutter/material.dart';

class AndroidStretchScrollBehavior extends MaterialScrollBehavior {
  // needed so the object can be instantiated as a const
  const AndroidStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // choose and build the overscroll indicator
    return StretchingOverscrollIndicator(
      axisDirection: details.direction,
      child: child,
    );
  }
}
