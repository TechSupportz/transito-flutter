import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:transito/global/providers/quick_start_tour_provider.dart';
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
  );
  late final QuickStartTourNavigatorObserver _observer = QuickStartTourNavigatorObserver(
    _controller,
  );

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
          QuickStartTourOverlay(controller: _controller),
        ],
      ),
    );
  }
}
