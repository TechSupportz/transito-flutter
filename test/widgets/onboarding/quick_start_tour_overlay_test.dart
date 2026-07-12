import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transito/global/providers/quick_start_tour_provider.dart';
import 'package:transito/widgets/onboarding/quick_start_tour_overlay.dart';

void main() {
  testWidgets('coach placement stays stable while a target changes', (WidgetTester tester) async {
    final ValueNotifier<bool> showTarget = ValueNotifier<bool>(true);
    addTearDown(showTarget.dispose);

    await tester.pumpWidget(_OverlayHarness(showTarget: showTarget));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 250));

    final double settledTop = tester.getTopLeft(find.byType(Card)).dy;

    showTarget.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.getTopLeft(find.byType(Card)).dy, settledTop);
  });

  testWidgets('interactive target activation fades the spotlight', (WidgetTester tester) async {
    final ValueNotifier<bool> showTarget = ValueNotifier<bool>(true);
    late QuickStartTourController controller;
    addTearDown(showTarget.dispose);

    await tester.pumpWidget(
      _OverlayHarness(
        showTarget: showTarget,
        onController: (QuickStartTourController value) => controller = value,
      ),
    );
    controller.next();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 250));

    AnimatedOpacity spotlight = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
    expect(spotlight.opacity, 1);

    controller.registry.activate(QuickStartTarget.firstNearbyStop);
    await tester.pump();

    spotlight = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
    expect(spotlight.opacity, 0);
  });

  testWidgets('coach card keeps stable horizontal margins across copy changes', (
    WidgetTester tester,
  ) async {
    final ValueNotifier<bool> showTarget = ValueNotifier<bool>(true);
    late QuickStartTourController controller;
    addTearDown(showTarget.dispose);

    await tester.pumpWidget(
      _OverlayHarness(
        showTarget: showTarget,
        onController: (QuickStartTourController value) => controller = value,
      ),
    );
    await tester.pump(const Duration(milliseconds: 550));
    final double initialWidth = tester.getSize(find.byType(Card)).width;

    for (int index = 0; index < 5; index++) {
      controller.next();
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.getSize(find.byType(Card)).width, initialWidth);
  });
}

class _OverlayHarness extends StatefulWidget {
  const _OverlayHarness({required this.showTarget, this.onController});

  final ValueListenable<bool> showTarget;
  final ValueChanged<QuickStartTourController>? onController;

  @override
  State<_OverlayHarness> createState() => _OverlayHarnessState();
}

class _OverlayHarnessState extends State<_OverlayHarness> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final QuickStartTourController _controller = QuickStartTourController(
    navigatorKey: _navigatorKey,
    onFinished: () {},
  );

  @override
  void initState() {
    super.initState();
    widget.onController?.call(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: QuickStartTargetScope(
        registry: _controller.registry,
        child: Stack(
          children: [
            Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: widget.showTarget,
                builder: (BuildContext context, bool showTarget, Widget? child) {
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (BuildContext context, Widget? child) {
                      return Stack(
                        children: [
                          if (showTarget)
                            Positioned(
                              left: 80,
                              right: 80,
                              bottom: 40,
                              child: FilledButton(
                                key: _controller.registry.keyFor(_controller.step.target),
                                onPressed: () {},
                                child: const Text('Target'),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            QuickStartTourOverlay(controller: _controller),
          ],
        ),
      ),
    );
  }
}
