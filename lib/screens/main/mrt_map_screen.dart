import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';

class MrtMapScreen extends StatelessWidget {
  const MrtMapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text('MRT Map'),
      ),
      // displays a zoomable mrt map (yes that's literally the only thing this whole screen does)
      body: PhotoView(
        maxScale: PhotoViewComputedScale.contained * 7.5,
        minScale: PhotoViewComputedScale.contained,
        initialScale: PhotoViewComputedScale.covered,
        imageProvider: const AssetImage('assets/images/mrt_map.png'),
      ),
    );
  }
}
