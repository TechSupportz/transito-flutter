import 'dart:async';

import 'package:flutter/material.dart';

enum QuickStartTarget {
  nearbyOverview,
  firstNearbyStop,
  firstTimingRow,
  timingTools,
  timingStopName,
  stopInfoPage,
  stopInfoReturn,
  timingServiceNumber,
  serviceInfoPage,
  serviceInfoBack,
  nearbyTab,
  searchTab,
  searchField,
  searchMap,
  mrtMapButton,
  mrtMap,
  settingsButton,
  settingsPreferences,
}

enum QuickStartPhase {
  nearby,
  pickStop,
  readArrivals,
  timingTools,
  stopDetailsEntry,
  stopDetailsOverview,
  stopDetailsReturn,
  serviceDetailsEntry,
  serviceDetailsOverview,
  serviceDetailsReturn,
  searchTab,
  searchField,
  map,
  mrtEntry,
  mrtMap,
  settingsNearbyTab,
  settingsButton,
  settingsPreferences,
}

enum QuickStartContentKind { text, arrivalLegend }

enum QuickStartMissingTargetAction { none, openFallbackStop, continueTour }

enum QuickStartHighlightBehavior { spotlight, pagePulse }

enum QuickStartCoachPlacement { automatic, top, bottom }

class QuickStartTargetRegistry extends ChangeNotifier {
  QuickStartTargetRegistry({required this.onTargetActivated});

  final ValueChanged<QuickStartTarget> onTargetActivated;
  QuickStartTarget? _activeTarget;
  QuickStartTarget? get activeTarget => _activeTarget;

  final Map<QuickStartTarget, GlobalKey> _keys = {
    for (final QuickStartTarget target in QuickStartTarget.values)
      target: GlobalKey(debugLabel: target.name),
  };
  final Map<QuickStartTarget, bool?> _availability = {};

  GlobalKey keyFor(QuickStartTarget target) => _keys[target]!;

  bool? availabilityFor(QuickStartTarget target) => _availability[target];

  void activate(QuickStartTarget target) => onTargetActivated(target);

  void setActiveTarget(QuickStartTarget target) {
    if (_activeTarget == target) return;
    _activeTarget = target;
    notifyListeners();
  }

  void setTargetAvailability(QuickStartTarget target, bool? isAvailable) {
    if (_availability[target] == isAvailable && _availability.containsKey(target)) return;
    _availability[target] = isAvailable;
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

  static void reportAvailability(
    BuildContext context,
    QuickStartTarget target,
    bool? isAvailable,
  ) {
    final QuickStartTargetRegistry? registry = maybeOf(context);
    if (registry == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        registry.setTargetAvailability(target, isAvailable);
      }
    });
  }

  @override
  bool updateShouldNotify(QuickStartTargetScope oldWidget) => registry != oldWidget.registry;
}

class QuickStartTourStep {
  const QuickStartTourStep({
    required this.phase,
    required this.visibleMoment,
    required this.target,
    required this.title,
    required this.message,
    this.contentKind = QuickStartContentKind.text,
    this.highlightBehavior = QuickStartHighlightBehavior.spotlight,
    this.coachPlacement = QuickStartCoachPlacement.automatic,
    this.allowsInteraction = false,
    this.primaryLabel = 'Next',
    this.secondaryLabel = 'Skip to end',
    this.showSecondaryAction = true,
    this.showPrimaryAction = true,
    this.spotlightRadius = 14,
    this.missingTargetAction = QuickStartMissingTargetAction.none,
    this.missingTargetLabel,
    this.passiveLabel,
  });

  final QuickStartPhase phase;
  final int visibleMoment;
  final QuickStartTarget target;
  final String title;
  final String message;
  final QuickStartContentKind contentKind;
  final QuickStartHighlightBehavior highlightBehavior;
  final QuickStartCoachPlacement coachPlacement;
  final bool allowsInteraction;
  final String primaryLabel;
  final String secondaryLabel;
  final bool showSecondaryAction;
  final bool showPrimaryAction;
  final double spotlightRadius;
  final QuickStartMissingTargetAction missingTargetAction;
  final String? missingTargetLabel;
  final String? passiveLabel;

  double get progress => (visibleMoment + 1) / QuickStartTourController.visibleMomentCount;
}

class QuickStartTourController extends ChangeNotifier {
  QuickStartTourController({
    required this.navigatorKey,
    required this.onFinished,
    this.onOpenFallbackStop,
    this.onOpenSettings,
    QuickStartPhase initialPhase = QuickStartPhase.nearby,
  }) {
    registry = QuickStartTargetRegistry(onTargetActivated: _targetActivated)..addListener(_refresh);
    _stepIndex = steps.indexWhere((QuickStartTourStep step) => step.phase == initialPhase);
    if (_stepIndex < 0) {
      _stepIndex = 0;
    }
    registry.setActiveTarget(step.target);
  }

  static const int visibleMomentCount = 10;

  final GlobalKey<NavigatorState> navigatorKey;
  final VoidCallback onFinished;
  final Future<void> Function()? onOpenFallbackStop;
  final VoidCallback? onOpenSettings;
  late final QuickStartTargetRegistry registry;
  Timer? _pendingAdvance;
  QuickStartTarget? _dismissedTarget;
  late int _stepIndex;
  bool _isOpeningFallback = false;
  bool _isEnding = false;
  bool _isReturningToRoot = false;
  QuickStartPhase? _phaseAfterReturningToRoot;
  String? _primaryError;

  static const List<QuickStartTourStep> steps = [
    QuickStartTourStep(
      phase: QuickStartPhase.nearby,
      visibleMoment: 0,
      target: QuickStartTarget.nearbyOverview,
      title: 'Nearby',
      message: 'Nearby favourites and bus stops are based on your current location.',
      highlightBehavior: QuickStartHighlightBehavior.pagePulse,
      coachPlacement: QuickStartCoachPlacement.bottom,
    ),
    QuickStartTourStep(
      phase: QuickStartPhase.pickStop,
      visibleMoment: 1,
      target: QuickStartTarget.firstNearbyStop,
      title: 'Pick a stop',
      message: 'Tap a stop to view its live arrivals.',
      allowsInteraction: true,
      showPrimaryAction: false,
      missingTargetAction: QuickStartMissingTargetAction.openFallbackStop,
      missingTargetLabel: 'Open bus timing screen',
    ),
    QuickStartTourStep(
      phase: QuickStartPhase.readArrivals,
      visibleMoment: 2,
      target: QuickStartTarget.firstTimingRow,
      title: 'Read arrivals',
      message: 'Arrival colours and labels explain what is coming next.',
      contentKind: QuickStartContentKind.arrivalLegend,
    ),
    QuickStartTourStep(
      phase: QuickStartPhase.timingTools,
      visibleMoment: 3,
      target: QuickStartTarget.timingTools,
      title: 'Timing tools',
      message: 'Try sorting by service or arrival time. The heart manages this stop in Favourites.',
      allowsInteraction: true,
      spotlightRadius: 12,
    ),
    QuickStartTourStep(
      phase: QuickStartPhase.stopDetailsEntry,
      visibleMoment: 4,
      target: QuickStartTarget.timingStopName,
      title: 'Stop details',
      message: 'Tap the stop name to see its address, services, and location details.',
      allowsInteraction: true,
      showPrimaryAction: false,
      spotlightRadius: 10,
    ),
    QuickStartTourStep(
      phase: QuickStartPhase.stopDetailsOverview,
      visibleMoment: 4,
      target: QuickStartTarget.stopInfoPage,
      title: 'Stop details',
      message: 'This page brings the stop address, operating services, map, and timings together.',
      highlightBehavior: QuickStartHighlightBehavior.pagePulse,
      coachPlacement: QuickStartCoachPlacement.bottom,
      primaryLabel: 'Continue',
    ),
    QuickStartTourStep(
      phase: QuickStartPhase.stopDetailsReturn,
      visibleMoment: 4,
      target: QuickStartTarget.stopInfoReturn,
      title: 'Stop details',
      message: 'This page keeps useful stop information together. Return to live timings.',
      allowsInteraction: true,
      showPrimaryAction: false,
      spotlightRadius: 12,
    ),
    QuickStartTourStep(
      phase: QuickStartPhase.serviceDetailsEntry,
      visibleMoment: 5,
      target: QuickStartTarget.timingServiceNumber,
      title: 'Service details',
      message: 'Tap a service number to inspect its route and stops.',
      allowsInteraction: true,
      showPrimaryAction: false,
      missingTargetAction: QuickStartMissingTargetAction.continueTour,
      missingTargetLabel: 'Continue to Search',
      spotlightRadius: 10,
    ),
    QuickStartTourStep(
      phase: QuickStartPhase.serviceDetailsOverview,
      visibleMoment: 5,
      target: QuickStartTarget.serviceInfoPage,
      title: 'Service details',
      message: 'This page shows the service route, direction, interchanges, and every stop.',
      highlightBehavior: QuickStartHighlightBehavior.pagePulse,
      coachPlacement: QuickStartCoachPlacement.bottom,
      showPrimaryAction: false,
      passiveLabel: 'Route controls appear shortly…',
    ),
    QuickStartTourStep(
      phase: QuickStartPhase.serviceDetailsReturn,
      visibleMoment: 5,
      target: QuickStartTarget.serviceInfoBack,
      title: 'Service details',
      message: 'Service information shows the full route. Go back when you are ready.',
      allowsInteraction: true,
      showPrimaryAction: false,
      spotlightRadius: 12,
    ),
    QuickStartTourStep(
      phase: QuickStartPhase.searchTab,
      visibleMoment: 6,
      target: QuickStartTarget.searchTab,
      title: 'Search',
      message: 'Tap Search to find a bus stop, road, or place.',
      allowsInteraction: true,
      showPrimaryAction: false,
      spotlightRadius: 12,
    ),
    QuickStartTourStep(
      phase: QuickStartPhase.searchField,
      visibleMoment: 6,
      target: QuickStartTarget.searchField,
      title: 'Search',
      message: 'Use this field whenever you need to look beyond your current location.',
      spotlightRadius: 12,
    ),
    QuickStartTourStep(
      phase: QuickStartPhase.map,
      visibleMoment: 7,
      target: QuickStartTarget.searchMap,
      title: 'Map',
      message: 'Drag to pan. Pinch to zoom or rotate. Tap the compass to reset north.',
      highlightBehavior: QuickStartHighlightBehavior.pagePulse,
      coachPlacement: QuickStartCoachPlacement.bottom,
      allowsInteraction: true,
    ),
    QuickStartTourStep(
      phase: QuickStartPhase.mrtEntry,
      visibleMoment: 8,
      target: QuickStartTarget.mrtMapButton,
      title: 'MRT map',
      message: 'Tap MRT Map for a network-wide rail reference.',
      allowsInteraction: true,
      showPrimaryAction: false,
      spotlightRadius: 12,
    ),
    QuickStartTourStep(
      phase: QuickStartPhase.mrtMap,
      visibleMoment: 8,
      target: QuickStartTarget.mrtMap,
      title: 'MRT map',
      message: 'Drag to pan and pinch to zoom around the rail map.',
      highlightBehavior: QuickStartHighlightBehavior.pagePulse,
      coachPlacement: QuickStartCoachPlacement.bottom,
      allowsInteraction: true,
      primaryLabel: 'Continue',
    ),
    QuickStartTourStep(
      phase: QuickStartPhase.settingsNearbyTab,
      visibleMoment: 9,
      target: QuickStartTarget.nearbyTab,
      title: 'Make it yours',
      message: 'Return to Nearby to open your app settings.',
      allowsInteraction: true,
      showPrimaryAction: false,
      spotlightRadius: 12,
    ),
    QuickStartTourStep(
      phase: QuickStartPhase.settingsButton,
      visibleMoment: 9,
      target: QuickStartTarget.settingsButton,
      title: 'Make it yours',
      message: 'Open Settings to choose your defaults.',
      allowsInteraction: true,
      showPrimaryAction: false,
      spotlightRadius: 12,
    ),
    QuickStartTourStep(
      phase: QuickStartPhase.settingsPreferences,
      visibleMoment: 9,
      target: QuickStartTarget.settingsPreferences,
      title: 'Quick Start complete',
      message:
          'You’re all set. Explore Settings to customise your experience, or return to Nearby.',
      highlightBehavior: QuickStartHighlightBehavior.pagePulse,
      coachPlacement: QuickStartCoachPlacement.top,
      allowsInteraction: true,
      primaryLabel: 'Back to Nearby',
      showSecondaryAction: false,
    ),
  ];

  int get stepIndex => _stepIndex;
  QuickStartTourStep get step => steps[_stepIndex];
  bool get isSpotlightDismissed => _dismissedTarget == step.target;
  bool get isOverlayVisible => !_isEnding;
  bool get isPrimaryActionLoading => _isOpeningFallback;
  String? get primaryError => _primaryError;

  bool get isCurrentTargetUnavailable => isTargetUnavailable(step);

  bool isTargetUnavailable(QuickStartTourStep candidate) {
    return registry.availabilityFor(candidate.target) == false;
  }

  bool get showPrimaryAction => showPrimaryActionFor(step);

  bool showPrimaryActionFor(QuickStartTourStep candidate) {
    return candidate.showPrimaryAction ||
        (isTargetUnavailable(candidate) &&
            candidate.missingTargetAction != QuickStartMissingTargetAction.none);
  }

  String get primaryLabel => primaryLabelFor(step);

  String primaryLabelFor(QuickStartTourStep candidate) {
    if (isTargetUnavailable(candidate) && candidate.missingTargetLabel != null) {
      return candidate.missingTargetLabel!;
    }
    return candidate.primaryLabel;
  }

  String targetInstruction({required bool targetIsVisible}) {
    return targetInstructionFor(step, targetIsVisible: targetIsVisible);
  }

  String targetInstructionFor(
    QuickStartTourStep candidate, {
    required bool targetIsVisible,
  }) {
    if (candidate.highlightBehavior == QuickStartHighlightBehavior.pagePulse) {
      return candidate.passiveLabel ?? 'Take a look around';
    }
    if (candidate.phase == QuickStartPhase.pickStop &&
        registry.availabilityFor(QuickStartTarget.firstNearbyStop) == null) {
      return 'Finding nearby stops…';
    }
    if (!targetIsVisible) {
      return 'Waiting for this screen…';
    }
    return 'Tap the highlighted control';
  }

  Future<void> onPrimaryPressed() async {
    _primaryError = null;
    if (isCurrentTargetUnavailable) {
      switch (step.missingTargetAction) {
        case QuickStartMissingTargetAction.openFallbackStop:
          await _openFallbackStop();
          return;
        case QuickStartMissingTargetAction.continueTour:
          _returnToRootAndSetPhase(QuickStartPhase.searchTab);
          return;
        case QuickStartMissingTargetAction.none:
          break;
      }
    }
    next();
  }

  void onSecondaryPressed() {
    final VoidCallback? openSettings = onOpenSettings;
    if (openSettings == null) {
      onFinished();
      return;
    }

    _dismissCurrentSpotlight();
    _pendingAdvance?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final NavigatorState? navigator = navigatorKey.currentState;
      if (navigator == null) {
        onFinished();
        return;
      }

      _isReturningToRoot = true;
      navigator.popUntil((Route<dynamic> route) => route.isFirst);
      _isReturningToRoot = false;
      _setPhase(QuickStartPhase.settingsPreferences);
      WidgetsBinding.instance.addPostFrameCallback((_) => openSettings());
    });
  }

  void next() {
    switch (step.phase) {
      case QuickStartPhase.mrtMap:
        _returnToRootAndSetPhase(QuickStartPhase.settingsNearbyTab);
        return;
      case QuickStartPhase.settingsPreferences:
        _endTour(returnToNearby: true);
        return;
      default:
        if (_stepIndex == steps.length - 1) {
          onFinished();
          return;
        }
        _setStep(_stepIndex + 1);
    }
  }

  Future<void> _openFallbackStop() async {
    final Future<void> Function()? callback = onOpenFallbackStop;
    if (callback == null || _isOpeningFallback) return;
    _isOpeningFallback = true;
    notifyListeners();
    try {
      await callback();
    } catch (error) {
      _primaryError = 'Could not open the fallback stop. Try again.';
      debugPrint('Failed to open Quick Start fallback stop: $error');
    } finally {
      _isOpeningFallback = false;
      notifyListeners();
    }
  }

  void _refresh() => notifyListeners();

  void _setPhase(QuickStartPhase phase) {
    final int index = steps.indexWhere((QuickStartTourStep step) => step.phase == phase);
    if (index >= 0) {
      _setStep(index);
    }
  }

  void _setStep(int index) {
    if (index < 0 || index >= steps.length || index == _stepIndex) return;
    _pendingAdvance?.cancel();
    _stepIndex = index;
    _dismissedTarget = null;
    _primaryError = null;
    registry.setActiveTarget(step.target);
    notifyListeners();
  }

  void _dismissCurrentSpotlight() {
    if (_dismissedTarget == step.target) return;
    _dismissedTarget = step.target;
    notifyListeners();
  }

  void _dismissAndSchedulePhase(QuickStartPhase phase) {
    _dismissCurrentSpotlight();
    _pendingAdvance?.cancel();
    _pendingAdvance = Timer(const Duration(milliseconds: 80), () => _setPhase(phase));
  }

  void _endTour({required bool returnToNearby}) {
    if (_isEnding) return;
    _isEnding = true;
    _dismissCurrentSpotlight();
    _pendingAdvance?.cancel();
    notifyListeners();
    if (returnToNearby) {
      _pendingAdvance = Timer(const Duration(milliseconds: 180), onFinished);
    }
  }

  void _showServiceDetailsOverview() {
    _dismissCurrentSpotlight();
    _pendingAdvance?.cancel();
    _pendingAdvance = Timer(const Duration(milliseconds: 80), () {
      _setPhase(QuickStartPhase.serviceDetailsOverview);
      _pendingAdvance = Timer(
        const Duration(seconds: 3),
        () => _setPhase(QuickStartPhase.serviceDetailsReturn),
      );
    });
  }

  void _returnToRootAndSetPhase(QuickStartPhase phase) {
    _dismissCurrentSpotlight();
    _pendingAdvance?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final NavigatorState? navigator = navigatorKey.currentState;
      if (navigator == null || !navigator.canPop()) {
        _setPhase(phase);
        return;
      }

      _isReturningToRoot = true;
      _phaseAfterReturningToRoot = phase;
      navigator.popUntil((Route<dynamic> route) => route.isFirst);
    });
  }

  void _targetActivated(QuickStartTarget target) {
    if (target != step.target) return;
    if (step.allowsInteraction) {
      _dismissCurrentSpotlight();
    }
    switch (target) {
      case QuickStartTarget.searchTab:
        _dismissAndSchedulePhase(QuickStartPhase.searchField);
      case QuickStartTarget.nearbyTab:
        _dismissAndSchedulePhase(QuickStartPhase.settingsButton);
      case QuickStartTarget.settingsPreferences:
        _endTour(returnToNearby: false);
      default:
        break;
    }
  }

  void routePushed(String? routeName) {
    switch ((routeName, step.phase)) {
      case ('BusTimingScreen', QuickStartPhase.pickStop):
        _dismissAndSchedulePhase(QuickStartPhase.readArrivals);
      case ('BusStopInfoScreen', QuickStartPhase.stopDetailsEntry):
        _dismissAndSchedulePhase(QuickStartPhase.stopDetailsOverview);
      case ('BusServiceInfoScreen', QuickStartPhase.serviceDetailsEntry):
        _showServiceDetailsOverview();
      case ('MrtMapScreen', QuickStartPhase.mrtEntry):
        _dismissAndSchedulePhase(QuickStartPhase.mrtMap);
      case ('SettingsScreen', QuickStartPhase.settingsButton):
        _dismissAndSchedulePhase(QuickStartPhase.settingsPreferences);
      default:
        break;
    }
  }

  void routePopped(String? routeName) {
    if (_isReturningToRoot) {
      final NavigatorState? navigator = navigatorKey.currentState;
      if (navigator?.canPop() ?? false) return;

      _isReturningToRoot = false;
      final QuickStartPhase? nextPhase = _phaseAfterReturningToRoot;
      _phaseAfterReturningToRoot = null;
      if (nextPhase != null) {
        _setPhase(nextPhase);
      }
      return;
    }
    switch (routeName) {
      case 'BusStopInfoScreen'
          when step.phase == QuickStartPhase.stopDetailsOverview ||
              step.phase == QuickStartPhase.stopDetailsReturn:
        _dismissAndSchedulePhase(QuickStartPhase.serviceDetailsEntry);
      case 'BusServiceInfoScreen'
          when step.phase == QuickStartPhase.serviceDetailsOverview ||
              step.phase == QuickStartPhase.serviceDetailsReturn:
        _returnToRootAndSetPhase(QuickStartPhase.searchTab);
      case 'SettingsScreen' when _isEnding:
        onFinished();
      case 'SettingsScreen' when step.phase == QuickStartPhase.settingsPreferences:
        _dismissAndSchedulePhase(QuickStartPhase.settingsButton);
      default:
        break;
    }
  }

  @override
  void dispose() {
    _pendingAdvance?.cancel();
    registry
      ..removeListener(_refresh)
      ..dispose();
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

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    final completion = route is TransitionRoute<dynamic> ? route.completed : route.popped;
    completion.then((_) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => controller.routePopped(route.settings.name),
      );
    });
  }
}
