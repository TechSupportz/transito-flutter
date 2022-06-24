import 'package:flutter/material.dart';

class BusServiceInfoScreen extends StatelessWidget {
  const BusServiceInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Service Info'),
      ),
      body: const Center(
        child: Text('Bus Service Info'),
      ),
    );
  }
}
