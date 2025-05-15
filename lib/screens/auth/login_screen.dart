import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:is_first_run/is_first_run.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/screens/auth/email_screen.dart';

import '../../global/services/authentication_service.dart';
import '../navigator_screen.dart';
import '../onboarding/location_access_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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

  void onAppleBtnPress() async {
    final bool isAppleSignInAvailable = await SignInWithApple.isAvailable();

    if (!isAppleSignInAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Sign in with Apple is not available on this device. Please try another method.'),
          ),
        );
      }
      return;
    }

    AuthenticationService().signInWithApple().then(
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

  void onEmailBtnPress() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EmailScreen(),
        settings: const RouteSettings(name: 'EmailScreen'),
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
    bool isFirstRun = await IsFirstRun.isFirstRun();
    LocationPermission permission = await Geolocator.checkPermission();
    if (!isFirstRun && permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      _defaultHome = const NavigatorScreen();
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
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [Color(0xAA3C18BF), Color(0xAA3C18BF).withAlpha(0)],
                              stops: [0, 1],
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: SvgPicture.asset('assets/images/logo.svg', height: 200),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'The last bus timing app you\'ll ever need.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.kindaGrey,
                                fontWeight: FontWeight.w200,
                              ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              spacing: 12,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                FilledButton.icon(
                                  onPressed: () => onGoogleBtnPress(),
                                  icon: SvgPicture.asset(
                                    'assets/images/google_logo.svg',
                                    height: 20,
                                    width: 20,
                                  ),
                                  label: const Text(
                                    'Continue with Google',
                                    style: TextStyle(color: Color(0xFF1F1F1F)),
                                  ),
                                  style: ButtonStyle(
                                    padding: WidgetStateProperty.all<EdgeInsets>(
                                      const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    backgroundColor: WidgetStateProperty.all<Color>(
                                      Color(0xFFF2F2F2),
                                    ),
                                  ),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: () => onAppleBtnPress(),
                                  icon: SvgPicture.asset(
                                    'assets/images/apple_logo.svg',
                                    height: 20,
                                    width: 20,
                                  ),
                                  label: const Text(
                                    'Continue with Apple',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ButtonStyle(
                                    padding: WidgetStateProperty.all<EdgeInsets>(
                                      const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    backgroundColor: WidgetStateProperty.all<Color>(
                                      Colors.black,
                                    ),
                                  ),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: () => onEmailBtnPress(),
                                  icon: Icon(Icons.email_rounded, color: AppColors.kindaGrey),
                                  label: const Text(
                                    'Continue with Email',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ButtonStyle(
                                    padding: WidgetStateProperty.all<EdgeInsets>(
                                      const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => showGuestLoginDialog(),
                                  icon: Icon(
                                    Icons.person_rounded,
                                    color: AppColors.kindaGrey,
                                  ),
                                  label: const Text(
                                    'Continue as a Guest',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ButtonStyle(
                                    padding: WidgetStateProperty.all<EdgeInsets>(
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
