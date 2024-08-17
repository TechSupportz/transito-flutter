import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:is_first_run/is_first_run.dart';
import 'package:transito/screens/navigator_screen.dart';
import 'package:transito/screens/onboarding/quick_start_screen.dart';

class LocationAccessScreen extends StatefulWidget {
  const LocationAccessScreen({super.key});

  @override
  State<LocationAccessScreen> createState() => _LocationAccessScreenState();
}

class _LocationAccessScreenState extends State<LocationAccessScreen> {
  late bool _isFirstRun;

  // function to check if the app is being run for the first time
  void checkIfFirstRun() async {
    bool isFirstRun = await IsFirstRun.isFirstRun();
    setState(() {
      _isFirstRun = isFirstRun;
    });
  }

  // function to send the user to the main screen
  void goToMainScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const NavigatorScreen(),
      ),
    );
  }

  // function to send the user to the quick start screen
  void goToQuickStart() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const QuickStartScreen(),
        settings: const RouteSettings(name: 'QuickStartScreen'),
      ),
    );
  }

  // function to check and request for the user's location permission in order to access their location
  Future<void> requestLocationPermission(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        // if the user has denied location permission forever, show a dialog (which is not dismissible) to the user to open the settings app
        showDialog(
          context: context,
          barrierDismissible: false, // user must tap button!
          builder: (context) => AlertDialog(
            title: const Text('Location Permission Denied'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Location permission is required to use key features of this app.'),
                SizedBox(height: 8),
                Text('Please enable location permission via your settings.'),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Open Settings'),
                onPressed: () {
                  Geolocator.openAppSettings();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
        // if the user has granted location permission and it is the first run, go to the quick start screen if it isn't the first run, go to the main screen
      } else {
        _isFirstRun ? goToQuickStart() : goToMainScreen();
      }
    } else {
      _isFirstRun ? goToQuickStart() : goToMainScreen();
    }
  }

  // check if it is the first run on the screen's initialization
  @override
  void initState() {
    super.initState();
    checkIfFirstRun();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hello there...'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'We need to access your location',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/images/location.svg',
                  placeholderBuilder: (context) => const CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                    'We need your location to determine where you are to display nearby bus stops',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton(
                onPressed: () => requestLocationPermission(context),
                child: const Text("Check Permission"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
