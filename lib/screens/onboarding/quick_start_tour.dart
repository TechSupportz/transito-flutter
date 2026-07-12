import 'dart:async';

import 'package:flutter/material.dart';

enum QuickStartTarget {
  nearbyFavourites,
  firstNearbyStop,
  firstTimingRow,
  timingSort,
  timingFavourite,
  nearbyTab,
  searchTab,
  searchField,
  searchMap,
  mrtMapButton,
  mrtMap,
  settingsButton,
  settingsPreferences,
}

class QuickStartTargetRegistry extends ChangeNotifier {
  QuickStartTargetRegistry({required this.onTargetActivated});

  final ValueChanged<QuickStartTarget> onTargetActivated;
  QuickStartTarget? _activeTarget;
  QuickStartTarget? get activeTarget => _activeTarget;
  final Map<QuickStartTarget, GlobalKey> _keys = {
    for (final QuickStartTarget target in QuickStartTarget.values)
      target: GlobalKey(debugLabel: target.name),
  };

  GlobalKey keyFor(QuickStartTarget target) => _keys[target]!;

  void activate(QuickStartTarget target) => onTargetActivated(target);

  void setActiveTarget(QuickStartTarget target) {
    if (_activeTarget == target) return;
    _activeTarget = target;
    notifyListeners();
  }
}

class QuickStartTargetScope extends InheritedWidget {
  const QuickStartTargetScope({
    super.key,
    required this.registry,
    required super.child,
  });

  final QuickStartTargetRegistry registry;

  static QuickStartTargetRegistry? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<QuickStartTargetScope>()?.registry;
  }

  static Key? keyOf(BuildContext context, QuickStartTarget target) {
    return maybeOf(context)?.keyFor(target);
  }

  static void activate(BuildContext context, QuickStartTarget target) {
    maybeOf(context)?.activate(target);
  }

  @override
  bool updateShouldNotify(QuickStartTargetScope oldWidget) => registry != oldWidget.registry;
}

class QuickStartTourStep {
  const QuickStartTourStep({
    required this.target,
    required this.title,
    required this.message,
    this.allowsInteraction = false,
    this.primaryLabel = 'Next',
    this.showPrimaryAction = true,
  });

  final QuickStartTarget target;
  final String title;
  final String message;
  final bool allowsInteraction;
  final String primaryLabel;
  final bool showPrimaryAction;
}

class QuickStartTourController extends ChangeNotifier {
  QuickStartTourController({required this.navigatorKey, required this.onFinished}) {
    registry = QuickStartTargetRegistry(onTargetActivated: _targetActivated);
    registry.setActiveTarget(step.target);
  }

  final GlobalKey<NavigatorState> navigatorKey;
  final VoidCallback onFinished;
  late QuickStartTargetRegistry registry;

  static const List<QuickStartTourStep> steps = [
    QuickStartTourStep(
      target: QuickStartTarget.nearbyFavourites,
      title: 'Favourites, when they matter',
      message: 'Saved stops appear here when you are nearby.',
    ),
    QuickStartTourStep(
      target: QuickStartTarget.firstNearbyStop,
      title: 'Open live timings',
      message: 'Tap any nearby stop. We’ll use the first one for this tour.',
      allowsInteraction: true,
      showPrimaryAction: false,
    ),
    QuickStartTourStep(
      target: QuickStartTarget.firstTimingRow,
      title: 'Read it at a glance',
      message:
          'Colour shows crowding; the tags cover access and bus type. Italics mean scheduled timing. Tap a service number for its route.',
    ),
    QuickStartTourStep(
      target: QuickStartTarget.timingSort,
      title: 'Try the sort',
      message: 'Switch between service order and soonest arrival. Try it once if you like.',
      allowsInteraction: true,
    ),
    QuickStartTourStep(
      target: QuickStartTarget.timingFavourite,
      title: 'Save the stop',
      message: 'The heart adds or edits a favourite. We won’t change yours during the tour.',
      primaryLabel: 'Continue to Search',
    ),
    QuickStartTourStep(
      target: QuickStartTarget.searchTab,
      title: 'Open Search',
      message: 'Tap Search in the navigation bar.',
      allowsInteraction: true,
      showPrimaryAction: false,
    ),
    QuickStartTourStep(
      target: QuickStartTarget.searchField,
      title: 'Find a place or stop',
      message: 'Search works the same way you would expect—no extra tour needed.',
    ),
    QuickStartTourStep(
      target: QuickStartTarget.searchMap,
      title: 'Move around the map',
      message:
          'Pan, zoom, and rotate freely. A compass appears after rotation so you can reset it.',
      allowsInteraction: true,
    ),
    QuickStartTourStep(
      target: QuickStartTarget.mrtMapButton,
      title: 'Open the MRT map',
      message: 'Tap MRT Map to bring up the full rail map.',
      allowsInteraction: true,
      showPrimaryAction: false,
    ),
    QuickStartTourStep(
      target: QuickStartTarget.mrtMap,
      title: 'Make the map comfortable',
      message: 'Pan and zoom the rail map until the whole route—or one station—is easy to read.',
      allowsInteraction: true,
      primaryLabel: 'Continue',
    ),
    QuickStartTourStep(
      target: QuickStartTarget.nearbyTab,
      title: 'Back to Nearby',
      message: 'Tap Nearby to finish where you started.',
      allowsInteraction: true,
      showPrimaryAction: false,
    ),
    QuickStartTourStep(
      target: QuickStartTarget.settingsButton,
      title: 'One last stop',
      message: 'Open Settings from the top-right corner.',
      allowsInteraction: true,
      showPrimaryAction: false,
    ),
    QuickStartTourStep(
      target: QuickStartTarget.settingsPreferences,
      title: 'Make Transito yours',
      message:
          'Timing format, Nearby layout, theme, colours, and favourite-card defaults live here.',
      primaryLabel: 'Finish',
    ),
  ];

  int _stepIndex = 0;
  int get stepIndex => _stepIndex;
  QuickStartTourStep get step => steps[_stepIndex];

  void next() {
    if (_stepIndex == 4) {
      navigatorKey.currentState?.popUntil((Route<dynamic> route) => route.isFirst);
      _setStep(5);
      return;
    }
    if (_stepIndex == 9) {
      navigatorKey.currentState?.popUntil((Route<dynamic> route) => route.isFirst);
      _setStep(10);
      return;
    }
    if (_stepIndex == steps.length - 1) {
      onFinished();
      return;
    }
    _setStep(_stepIndex + 1);
  }

  void _setStep(int index) {
    if (index < 0 || index >= steps.length || index == _stepIndex) return;
    _stepIndex = index;
    registry.setActiveTarget(step.target);
    notifyListeners();
  }

  void _targetActivated(QuickStartTarget target) {
    if (target != step.target) return;
    if (target == QuickStartTarget.searchTab) {
      _setStep(6);
    } else if (target == QuickStartTarget.nearbyTab) {
      _setStep(11);
    }
  }

  void routePushed(String? routeName) {
    if (routeName == 'BusTimingScreen' && _stepIndex == 1) {
      _setStep(2);
    } else if (routeName == 'MrtMapScreen' && _stepIndex == 8) {
      _setStep(9);
    } else if (routeName == 'SettingsScreen' && _stepIndex == 11) {
      _setStep(12);
    }
  }

  @override
  void dispose() {
    registry.dispose();
    super.dispose();
  }
}

class QuickStartTourNavigatorObserver extends NavigatorObserver {
  QuickStartTourNavigatorObserver(this.controller);

  final QuickStartTourController controller;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => controller.routePushed(route.settings.name),
    );
  }
}

class QuickStartTourOverlay extends StatefulWidget {
  const QuickStartTourOverlay({super.key, required this.controller});

  final QuickStartTourController controller;

  @override
  State<QuickStartTourOverlay> createState() => _QuickStartTourOverlayState();
}

class _QuickStartTourOverlayState extends State<QuickStartTourOverlay> {
  Timer? _refreshTimer;
  Rect? _targetRect;
  bool _revealingTarget = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleStepChanged);
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_targetRect == null) {
        _revealAndRefresh();
      } else {
        _refreshTarget();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealAndRefresh());
  }

  @override
  void didUpdateWidget(covariant QuickStartTourOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleStepChanged);
      widget.controller.addListener(_handleStepChanged);
      _revealAndRefresh();
    }
  }

  void _handleStepChanged() {
    if (!mounted) return;
    setState(() => _targetRect = null);
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealAndRefresh());
  }

  Future<void> _revealAndRefresh() async {
    if (_revealingTarget || !mounted) return;
    _revealingTarget = true;
    final BuildContext? targetContext = widget.controller.registry
        .keyFor(widget.controller.step.target)
        .currentContext;
    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 300),
        curve: Easing.emphasizedDecelerate,
        alignment: 0.35,
      );
    }
    if (mounted) {
      _refreshTarget();
      _revealingTarget = false;
    }
  }

  void _refreshTarget() {
    if (!mounted) return;
    final BuildContext? targetContext = widget.controller.registry
        .keyFor(widget.controller.step.target)
        .currentContext;
    final RenderObject? renderObject = targetContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      if (_targetRect != null) setState(() => _targetRect = null);
      return;
    }
    final Rect nextRect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    if (_targetRect != nextRect) setState(() => _targetRect = nextRect);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    widget.controller.removeListener(_handleStepChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final Rect? visibleTarget = _targetRect?.intersect(Offset.zero & size);
    final Rect? target = visibleTarget == null || visibleTarget.isEmpty
        ? null
        : visibleTarget.inflate(6).intersect(Offset.zero & size);
    final bool placeCoachAbove = target != null && target.center.dy > size.height * 0.55;
    final Color scrim = Colors.black.withValues(alpha: 0.68);
    final QuickStartTourStep step = widget.controller.step;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          if (target == null)
            Positioned.fill(child: ColoredBox(color: scrim))
          else ...[
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: target.top,
              child: ColoredBox(color: scrim),
            ),
            Positioned(
              left: 0,
              top: target.top,
              width: target.left,
              height: target.height,
              child: ColoredBox(color: scrim),
            ),
            Positioned(
              left: target.right,
              right: 0,
              top: target.top,
              height: target.height,
              child: ColoredBox(color: scrim),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: target.bottom,
              bottom: 0,
              child: ColoredBox(color: scrim),
            ),
            Positioned.fromRect(
              rect: target,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!step.allowsInteraction)
              Positioned.fromRect(
                rect: target,
                child: const AbsorbPointer(child: SizedBox.expand()),
              ),
          ],
          Align(
            alignment: placeCoachAbove ? Alignment.topCenter : Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  elevation: 8,
                  child: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.02, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      key: ValueKey<int>(widget.controller.stepIndex),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.controller.stepIndex + 1} of ${QuickStartTourController.steps.length}',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(step.title, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 6),
                          Text(step.message, style: Theme.of(context).textTheme.bodyLarge),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              TextButton(
                                onPressed: widget.controller.onFinished,
                                child: const Text('Skip'),
                              ),
                              const Spacer(),
                              if (step.showPrimaryAction)
                                FilledButton(
                                  onPressed: widget.controller.next,
                                  child: Text(step.primaryLabel),
                                )
                              else
                                Text(
                                  target == null
                                      ? 'Waiting for this screen…'
                                      : 'Tap the highlighted control',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
