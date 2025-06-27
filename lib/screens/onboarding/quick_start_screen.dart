import 'package:flutter/material.dart';
import 'package:transito/screens/navigator_screen.dart';
import 'package:transito/widgets/common/bus_timing_guide.dart';

class QuickStartScreen extends StatelessWidget {
  const QuickStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Almost there...'),
      ),
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'How to I decipher the details?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
              const BusTimingGuide(),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.0),
                ],
                stops: [0.9, 1.0],
              ),
            ),
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const NavigatorScreen(),
                ),
                (Route<dynamic> route) => false,
              ),
              child: const Text("Take me to the home screen!"),
            ),
          ),
        ),
      ]),
    );
  }
}
