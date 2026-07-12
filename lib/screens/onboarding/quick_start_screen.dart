import 'package:flutter/material.dart';
import 'package:transito/screens/main/settings_screen.dart';
import 'package:transito/screens/navigator_screen.dart';
import 'package:transito/screens/onboarding/quick_start_tour.dart';

class QuickStartScreen extends StatefulWidget {
  const QuickStartScreen({super.key, this.returnToSettings = false});

  final bool returnToSettings;

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
    if (widget.returnToSettings) {
      navigator.pop();
      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const _TutorialHome(),
        settings: const RouteSettings(name: 'NavigatorScreen'),
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

class _TutorialHome extends StatefulWidget {
  const _TutorialHome();

  @override
  State<_TutorialHome> createState() => _TutorialHomeState();
}

class _TutorialHomeState extends State<_TutorialHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const SettingsScreen(),
          settings: const RouteSettings(name: 'SettingsScreen'),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const NavigatorScreen();
}
