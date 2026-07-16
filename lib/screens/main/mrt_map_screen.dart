import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:transito/global/providers/quick_start_tour_provider.dart';

Route<void> buildMrtMapRoute(BuildContext context) {
  const settings = RouteSettings(name: 'MrtMapScreen');

  if (Theme.of(context).platform != TargetPlatform.iOS) {
    return MaterialPageRoute<void>(
      builder: (_) => const MrtMapScreen(),
      settings: settings,
    );
  }

  return PageRouteBuilder<void>(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, _, _) => const MrtMapScreen(),
    transitionsBuilder: (_, animation, _, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      );
    },
  );
}

class MrtMapScreen extends StatelessWidget {
  const MrtMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(title: const Text('MRT Map')),
      // displays a zoomable mrt map (yes that's literally the only thing this whole screen does)
      body: PhotoView(
        key: QuickStartTargetScope.keyOf(context, QuickStartTarget.mrtMap),
        onTapDown: (_, _, _) => QuickStartTargetScope.activate(context, QuickStartTarget.mrtMap),
        maxScale: PhotoViewComputedScale.contained * 7.5,
        minScale: PhotoViewComputedScale.contained,
        initialScale: PhotoViewComputedScale.covered,
        basePosition: Alignment.centerLeft,
        backgroundDecoration: BoxDecoration(
          color: Theme.of(context).brightness == .dark ? Colors.black : Colors.white,
        ),
        imageProvider: Theme.of(context).brightness == .dark
            ? AssetImage('assets/images/mrt_maps/mrt-map-dark.webp')
            : AssetImage('assets/images/mrt_maps/mrt-map-light.webp'),
      ),
    );
  }
}
