import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:is_first_run/is_first_run.dart';
import 'package:transito/models/app_colors.dart';
import 'package:transito/screens/auth/email_screen.dart';

import '../../providers/authentication_service.dart';
import '../navbar_screens/main_screen.dart';
import '../onboarding_screens/location_access_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Widget _defaultHome = const LocationAccessScreen();

  void onGoogleBtnPress() async {
    AuthenticationService().signInWithGoogle().then(
      (err) {
        if (err == null) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => _defaultHome,
            ),
            (Route<dynamic> route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Something went wrong... Please try again'),
            ),
          );
        }
      },
    );
  }

  void setIsGoogleLoading(bool value) {
    if (value) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Center(
            child: CircularProgressIndicator(
          strokeWidth: 3,
        )),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void onEmailBtnPress() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EmailScreen(),
      ),
    );
  }

  void onGuestLoginBtnPress() {
    AuthenticationService().signInAnonymously().then((err) {
      if (err == null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => _defaultHome,
          ),
          (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong... Please try again'),
          ),
        );
      }
    });
  }

  void showGuestLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => guestLoginDialog(context),
    );
  }

  initialiseDefaultHome() async {
    bool _isFirstRun = await IsFirstRun.isFirstRun();
    LocationPermission _permission = await Geolocator.checkPermission();
    if (!_isFirstRun && _permission == LocationPermission.always ||
        _permission == LocationPermission.whileInUse) {
      _defaultHome = const MainScreen();
    }
  }

  @override
  void initState() {
    super.initState();
    initialiseDefaultHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      // appBar: AppBar(title: const Text('Welcome!')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(overscroll: false),
          child: CustomScrollView(
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    const Spacer(),
                    Stack(
                      alignment: Alignment.center,
                      fit: StackFit.passthrough,
                      children: [
                        Container(
                          height: MediaQuery.of(context).size.width,
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                              colors: [Color(0xff542f95), Color(0xff0C0C0C)],
                              stops: [0, 0.85],
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: SvgPicture.asset('assets/images/logo.svg'),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Simply login and never miss a bus again!',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, color: AppColors.kindaGrey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF151515),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      margin: const EdgeInsets.only(bottom: 48),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => onGoogleBtnPress(),
                                  icon: SvgPicture.asset('assets/images/google_logo.svg'),
                                  label: const Text(
                                    'Continue with Google',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ButtonStyle(
                                    padding: MaterialStateProperty.all<EdgeInsets>(
                                      const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: () => onEmailBtnPress(),
                                  icon: const Icon(Icons.mail_outline_rounded,
                                      color: AppColors.kindaGrey),
                                  label: const Text(
                                    'Continue with Email',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ButtonStyle(
                                    padding: MaterialStateProperty.all<EdgeInsets>(
                                      const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: () => showGuestLoginDialog(),
                                  icon: const Icon(
                                    Icons.perm_identity_rounded,
                                    color: AppColors.kindaGrey,
                                  ),
                                  label: const Text(
                                    'Continue as a Guest',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ButtonStyle(
                                    padding: MaterialStateProperty.all<EdgeInsets>(
                                      const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AlertDialog guestLoginDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('Continue as a Guest'),
      content: const Text(
          'Using a guest account will prevent your favourites and setting from being synced. Are you sure you want to continue?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onGuestLoginBtnPress();
          },
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
