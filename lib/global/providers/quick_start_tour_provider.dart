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
    this.spotlightRadius = 14,
  });

  final QuickStartTarget target;
  final String title;
  final String message;
  final bool allowsInteraction;
  final String primaryLabel;
  final bool showPrimaryAction;
  final double spotlightRadius;
}

class QuickStartTourController extends ChangeNotifier {
  QuickStartTourController({required this.navigatorKey, required this.onFinished}) {
    registry = QuickStartTargetRegistry(onTargetActivated: _targetActivated);
    registry.setActiveTarget(step.target);
  }

  final GlobalKey<NavigatorState> navigatorKey;
  final VoidCallback onFinished;
  late QuickStartTargetRegistry registry;
  Timer? _pendingAdvance;
  QuickStartTarget? _dismissedTarget;

  bool get isSpotlightDismissed => _dismissedTarget == step.target;

  static const List<QuickStartTourStep> steps = [
    QuickStartTourStep(
      target: QuickStartTarget.nearbyFavourites,
      title: 'Nearby favourites',
      message: 'Favourites within 750 m appear here with live timings.',
    ),
    QuickStartTourStep(
      target: QuickStartTarget.firstNearbyStop,
      title: 'Open a nearby stop',
      message: 'Tap a stop to view its live arrivals.',
      allowsInteraction: true,
      showPrimaryAction: false,
    ),
    QuickStartTourStep(
      target: QuickStartTarget.firstTimingRow,
      title: 'Read bus arrivals',
      message:
          'Colour shows crowding. Icons and tags show wheelchair access and bus type. Italic times are schedule estimates. Tap a service number for its route.',
    ),
    QuickStartTourStep(
      target: QuickStartTarget.timingSort,
      title: 'Sort arrivals',
      message: 'Tap to sort by service number or next arrival.',
      allowsInteraction: true,
      spotlightRadius: 999,
    ),
    QuickStartTourStep(
      target: QuickStartTarget.timingFavourite,
      title: 'Save a bus stop',
      message: 'Use the heart to add this stop to Favourites. Nothing will change during the tour.',
      primaryLabel: 'Continue to Search',
      spotlightRadius: 999,
    ),
    QuickStartTourStep(
      target: QuickStartTarget.searchTab,
      title: 'Go to Search',
      message: 'Tap Search.',
      allowsInteraction: true,
      showPrimaryAction: false,
      spotlightRadius: 999,
    ),
    QuickStartTourStep(
      target: QuickStartTarget.searchField,
      title: 'Search the map',
      message: 'Find a bus stop, road, or place.',
      spotlightRadius: 999,
    ),
    QuickStartTourStep(
      target: QuickStartTarget.searchMap,
      title: 'Explore the map',
      message: 'Drag to pan. Pinch to zoom or rotate. Tap the compass to reset north.',
      allowsInteraction: true,
    ),
    QuickStartTourStep(
      target: QuickStartTarget.mrtMapButton,
      title: 'Open the MRT map',
      message: 'Tap MRT Map.',
      allowsInteraction: true,
      showPrimaryAction: false,
      spotlightRadius: 999,
    ),
    QuickStartTourStep(
      target: QuickStartTarget.mrtMap,
      title: 'Explore the MRT map',
      message: 'Drag to pan and pinch to zoom.',
      allowsInteraction: true,
      primaryLabel: 'Continue',
    ),
    QuickStartTourStep(
      target: QuickStartTarget.nearbyTab,
      title: 'Return to Nearby',
      message: 'Tap Nearby.',
      allowsInteraction: true,
      showPrimaryAction: false,
      spotlightRadius: 999,
    ),
    QuickStartTourStep(
      target: QuickStartTarget.settingsButton,
      title: 'Open Settings',
      message: 'Tap Settings in the top-right corner.',
      allowsInteraction: true,
      showPrimaryAction: false,
      spotlightRadius: 999,
    ),
    QuickStartTourStep(
      target: QuickStartTarget.settingsPreferences,
      title: 'Choose your defaults',
      message:
          'Change timing format, Nearby layout, theme, colours, and favourite-card behaviour here.',
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
    _pendingAdvance?.cancel();
    _stepIndex = index;
    _dismissedTarget = null;
    registry.setActiveTarget(step.target);
    notifyListeners();
  }

  void _dismissCurrentSpotlight() {
    if (_dismissedTarget == step.target) return;
    _dismissedTarget = step.target;
    notifyListeners();
  }

  void _dismissAndScheduleStep(int index) {
    _dismissCurrentSpotlight();
    _pendingAdvance?.cancel();
    _pendingAdvance = Timer(const Duration(milliseconds: 180), () => _setStep(index));
  }

  void _targetActivated(QuickStartTarget target) {
    if (target != step.target) return;
    if (step.allowsInteraction) {
      _dismissCurrentSpotlight();
    }
    if (target == QuickStartTarget.searchTab) {
      _dismissAndScheduleStep(6);
    } else if (target == QuickStartTarget.nearbyTab) {
      _dismissAndScheduleStep(11);
    }
  }

  void routePushed(String? routeName) {
    if (routeName == 'BusTimingScreen' && _stepIndex == 1) {
      _dismissAndScheduleStep(2);
    } else if (routeName == 'MrtMapScreen' && _stepIndex == 8) {
      _dismissAndScheduleStep(9);
    } else if (routeName == 'SettingsScreen' && _stepIndex == 11) {
      _dismissAndScheduleStep(12);
    }
  }

  @override
  void dispose() {
    _pendingAdvance?.cancel();
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
