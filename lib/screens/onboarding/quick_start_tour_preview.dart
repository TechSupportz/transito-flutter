import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:transito/screens/onboarding/quick_start_tour.dart';

@Preview(name: 'Quick start coachmark', group: 'Onboarding', size: Size(430, 900))
Widget quickStartCoachmarkPreview() => const MaterialApp(home: _QuickStartOverlayPreview());

class _QuickStartOverlayPreview extends StatefulWidget {
  const _QuickStartOverlayPreview();

  @override
  State<_QuickStartOverlayPreview> createState() => _QuickStartOverlayPreviewState();
}

class _QuickStartOverlayPreviewState extends State<_QuickStartOverlayPreview> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final QuickStartTourController _controller = QuickStartTourController(
    navigatorKey: _navigatorKey,
    onFinished: () {},
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QuickStartTargetScope(
      registry: _controller.registry,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(title: const Text('Welcome Alex')),
            body: Center(
              child: FilledButton(
                key: _controller.registry.keyFor(QuickStartTarget.nearbyFavourites),
                onPressed: () {},
                child: const Text('Nearby favourites'),
              ),
            ),
          ),
          QuickStartTourOverlay(controller: _controller),
        ],
      ),
    );
  }
}
