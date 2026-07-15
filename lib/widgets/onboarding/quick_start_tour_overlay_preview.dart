import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:transito/global/providers/quick_start_tour_provider.dart';
import 'package:transito/widgets/onboarding/quick_start_tour_overlay.dart';

@Preview(
  name: 'Arrival legend - light',
  group: 'Onboarding',
  size: Size(430, 900),
  brightness: Brightness.light,
)
@Preview(
  name: 'Arrival legend - dark',
  group: 'Onboarding',
  size: Size(430, 900),
  brightness: Brightness.dark,
)
Widget quickStartCoachmarkPreview() => const MaterialApp(home: _QuickStartOverlayPreview());

@Preview(name: 'Whole-page pulse', group: 'Onboarding', size: Size(430, 900))
Widget quickStartPagePulsePreview() => const MaterialApp(
  home: _QuickStartOverlayPreview(initialPhase: QuickStartPhase.nearby),
);

@Preview(name: 'Quick Start complete', group: 'Onboarding', size: Size(430, 900))
Widget quickStartCompletePreview() => const MaterialApp(
  home: _QuickStartOverlayPreview(initialPhase: QuickStartPhase.settingsPreferences),
);

class _QuickStartOverlayPreview extends StatefulWidget {
  const _QuickStartOverlayPreview({this.initialPhase = QuickStartPhase.readArrivals});

  final QuickStartPhase initialPhase;

  @override
  State<_QuickStartOverlayPreview> createState() => _QuickStartOverlayPreviewState();
}

class _QuickStartOverlayPreviewState extends State<_QuickStartOverlayPreview> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final QuickStartTourController _controller;

  @override
  void initState() {
    super.initState();
    _controller = QuickStartTourController(
      navigatorKey: _navigatorKey,
      onFinished: () {},
      initialPhase: widget.initialPhase,
    );
  }

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
            appBar: AppBar(
              title: Text(
                widget.initialPhase == QuickStartPhase.nearby
                    ? 'Welcome Alex'
                    : 'Temasek Polytechnic',
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                key: _controller.registry.keyFor(_controller.step.target),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('15', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                      Text('3  12  21', style: TextStyle(fontSize: 24)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          QuickStartTourOverlay(controller: _controller),
        ],
      ),
    );
  }
}
