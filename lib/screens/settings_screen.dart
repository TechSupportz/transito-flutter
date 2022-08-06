import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:transito/models/settings_card_options.dart';
import 'package:transito/models/user_settings.dart';
import 'package:transito/providers/authentication_service.dart';
import 'package:transito/widgets/settings_radio_card.dart';

import '../models/app_colors.dart';
import '../providers/settings_service.dart';
import '../widgets/error_text.dart';
import 'auth/login-screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameFieldKey = GlobalKey<FormBuilderFieldState>();
  bool _isNameFieldLoading = false;

  void updateDisplayName(User? user) async {
    setState(() {
      _isNameFieldLoading = true;
    });

    _nameFieldKey.currentState?.save();
    _nameFieldKey.currentState?.validate();

    if (_nameFieldKey.currentState!.isValid && user != null) {
      if (user.displayName != _nameFieldKey.currentState!.value) {
        try {
          await user.updateDisplayName(_nameFieldKey.currentState!.value).then((value) {
            setState(() {
              _isNameFieldLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Name updated successfully'),
              ),
            );
          });
        } catch (e) {
          debugPrint('❌ Unable to update name: $e');
          _nameFieldKey.currentState!.invalidate("Oops, something went wrong on our end");
        }
      } else {
        Timer(const Duration(milliseconds: 500), () {
          setState(() {
            _isNameFieldLoading = false;
          });
          _nameFieldKey.currentState!.invalidate("New name cannot be the same as previous");
        });
      }
    } else {
      _nameFieldKey.currentState!.invalidate("Oops, something went wrong on our end");
    }
  }

  void showResetPasswordDialog(String? email) {
    debugPrint('showResetPasswordDialog');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: const Text('Are you sure you want to reset your password?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: const Text('Yes'),
            onPressed: () {
              if (email != null) {
                AuthenticationService().sendPasswordResetEmail(email).then((_) {
                  Navigator.of(context).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password reset email sent to $email'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                });
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = context.watch<User?>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "About you",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                FormBuilderTextField(
                  key: _nameFieldKey,
                  name: 'name',
                  scrollPadding: const EdgeInsets.symmetric(vertical: 50),
                  initialValue: user?.displayName,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                  ]),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    suffixIcon: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.veryPurple,
                      ),
                      child: AnimatedSwitcher(
                          transitionBuilder: (child, animation) => ScaleTransition(
                                scale: animation,
                                child: child,
                              ),
                          duration: const Duration(milliseconds: 175),
                          child: _isNameFieldLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  ),
                                )
                              : IconButton(
                                  splashRadius: 1,
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    updateDisplayName(user);
                                  },
                                  icon: const Icon(
                                    Icons.check_rounded,
                                    size: 21,
                                    color: Colors.white,
                                  ),
                                )),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      (user != null &&
                              user.providerData.map((e) => e.providerId).contains('password'))
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: OutlinedButton(
                                onPressed: () => showResetPasswordDialog(user.email),
                                child: const Text(
                                  'Reset password',
                                  style: TextStyle(fontSize: 14, color: AppColors.veryPurple),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : const SizedBox(height: 0),
                      ElevatedButton(
                        onPressed: () => AuthenticationService()
                            .logout()
                            .then((value) => Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                  (Route<dynamic> route) => false,
                                )),
                        child: const Text(
                          'Logout',
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Aesthetics ✨",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 24),
                StreamBuilder(
                  stream: SettingsService().streamSettings(user?.uid),
                  builder: (context, AsyncSnapshot<UserSettings> snapshot) {
                    if (snapshot.hasData) {
                      return Column(
                        children: [
                          SettingsRadioCard(
                            title: "ETA Format",
                            initialValue: snapshot.data!.isETAminutes,
                            options: [
                              SettingsCardOption(value: true, text: "Minutes to arrival (2 mins)"),
                              SettingsCardOption(value: false, text: "Time of arrival (18:21)")
                            ],
                          ),
                          const SizedBox(height: 18),
                          SettingsRadioCard(
                            title: "Nearby Layout",
                            initialValue: snapshot.data!.isNearbyGrid,
                            options: [
                              SettingsCardOption(value: true, text: "Grid layout"),
                              SettingsCardOption(value: false, text: "Column layout")
                            ],
                          ),
                        ],
                      );
                    } else if (snapshot.hasError) {
                      return Container(
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: ErrorText(),
                          ));
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
