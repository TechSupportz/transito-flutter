import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:transito/global/providers/quick_start_tour_provider.dart';
import 'package:transito/global/services/transito_api_service.dart';
import 'package:transito/models/api/transito/bus_stops.dart';
import 'package:transito/screens/bus_info/bus_timing_screen.dart';
import 'package:transito/screens/navigator_screen.dart';
import 'package:transito/widgets/onboarding/quick_start_tour_overlay.dart';

class QuickStartScreen extends StatefulWidget {
  const QuickStartScreen({super.key});

  @override
  State<QuickStartScreen> createState() => _QuickStartScreenState();
}

class _QuickStartScreenState extends State<QuickStartScreen> {
  final GlobalKey<NavigatorState> _tourNavigatorKey = GlobalKey<NavigatorState>();
  late final QuickStartTourController _controller = QuickStartTourController(
    navigatorKey: _tourNavigatorKey,
    onFinished: _finish,
    onOpenFallbackStop: _openFallbackStop,
  );
  late final QuickStartTourNavigatorObserver _observer = QuickStartTourNavigatorObserver(
    _controller,
  );

  Future<void> _openFallbackStop() async {
    const String fallbackStopCode = '75239';
    final BusStop stop = await TransitoApiService().getBusStop(fallbackStopCode);
    if (!mounted) return;
    final NavigatorState? navigator = _tourNavigatorKey.currentState;
    if (navigator == null) {
      throw StateError('Quick Start navigator is unavailable');
    }
    navigator.push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => BusTimingScreen(
          code: stop.code,
          name: stop.name,
          address: stop.roadName,
          services: stop.services,
          sources: stop.sources,
          busStopLocation: LatLng(stop.latitude, stop.longitude),
        ),
        settings: const RouteSettings(name: 'BusTimingScreen'),
      ),
    );
  }

  void _finish() {
    final NavigatorState navigator = Navigator.of(context);
    navigator.pushAndRemoveUntil(
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: 'NavigatorScreen'),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) => const NavigatorScreen(),
        transitionsBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child,
            ) => FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            ),
      ),
      (Route<dynamic> route) => false,
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
          Navigator(
            key: _tourNavigatorKey,
            observers: [_observer],
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (BuildContext context) => const NavigatorScreen(),
              settings: const RouteSettings(name: 'NavigatorScreen'),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) => _controller.isOverlayVisible
                ? QuickStartTourOverlay(controller: _controller)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
