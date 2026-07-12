import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:transito/screens/onboarding/quick_start_tour.dart';

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
