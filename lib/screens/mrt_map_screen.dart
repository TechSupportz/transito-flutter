import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class MrtMapScreen extends StatelessWidget {
  const MrtMapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MRT Map'),
      ),
      body: PhotoView(
        imageProvider: AssetImage('assets/images/mrt_map.png'),
      ),
    );
  }
}
