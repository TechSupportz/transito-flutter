// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:is_first_run/is_first_run.dart';
import 'package:transito/screens/navbar_screens/main_screen.dart';
import 'package:transito/screens/onboarding_screens/quick_start_screen.dart';

import '../../models/app_colors.dart';

class LocationAccessScreen extends StatefulWidget {
  const LocationAccessScreen({Key? key}) : super(key: key);

  @override
  State<LocationAccessScreen> createState() => _LocationAccessScreenState();
}

class _LocationAccessScreenState extends State<LocationAccessScreen> {
  late bool _isFirstRun;

  void checkIfFirstRun() async {
    bool isFirstRun = await IsFirstRun.isFirstRun();
    setState(() {
      _isFirstRun = isFirstRun;
    });
  }

  void goToMainScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MainScreen(),
      ),
    );
  }

  void goToQuickStart() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => QuickStartScreen(),
      ),
    );
  }

  Future<void> requestLocationPermission(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        showDialog(
          context: context,
          barrierDismissible: false, // user must tap button!
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.cardBg,
            title: Text('Location Permission Denied'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Location permission is required to use key features of this app.'),
                SizedBox(height: 8),
                Text('Please enable location permission via your settings.'),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Open Settings'),
                onPressed: () {
                  Geolocator.openAppSettings();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      } else {
        _isFirstRun ? goToQuickStart() : goToMainScreen();
      }
    } else {
      _isFirstRun ? goToQuickStart() : goToMainScreen();
    }
  }

  @override
  void initState() {
    super.initState();
    checkIfFirstRun();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Almost there...'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
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
                  placeholderBuilder: (context) => CircularProgressIndicator(),
                ),
                const SizedBox(
                  height: 10,
                ),
                Text('We need your location to determine where you are to display nearby bus stops',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 42),
                child: ElevatedButton(
                  onPressed: () => requestLocationPermission(context),
                  child: Text("Check Permission"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
