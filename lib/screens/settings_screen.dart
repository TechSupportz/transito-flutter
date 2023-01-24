import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_extra_fields/form_builder_extra_fields.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:transito/models/settings_card_options.dart';
import 'package:transito/models/user_settings.dart';
import 'package:transito/providers/authentication_service.dart';
import 'package:transito/screens/onboarding_screens/quick_start_screen.dart';
import 'package:transito/widgets/settings_radio_card.dart';

import '../models/app_colors.dart';
import '../providers/settings_service.dart';
import '../widgets/error_text.dart';
import 'auth/login-screen.dart';
import 'navbar_screens/main_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameFieldKey = GlobalKey<FormBuilderFieldState>();
  final _accentColourFieldKey = GlobalKey<FormBuilderFieldState>();
  bool _isNameFieldLoading = false;
  final TextStyle titleStyle = const TextStyle(fontSize: 30, fontWeight: FontWeight.w700);

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

  void updateAccentColour(User? user) async {
    _accentColourFieldKey.currentState?.save();
    _accentColourFieldKey.currentState?.validate();

    if (_accentColourFieldKey.currentState!.isValid && user != null) {
      SettingsService()
          .updateAccentColour(
            userId: user.uid,
            newValue:
                '0x${_accentColourFieldKey.currentState!.value.toString().substring(8, 16).toUpperCase()}',
          )
          .then((_) => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Accent colour updated'),
                  content: const Text('A restart may be required for the change to take effect.'),
                  actions: [
                    TextButton(
                      child: const Text('Ok'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const MainScreen(),
                          ),
                          (Route<dynamic> route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ));
    }
  }

  void resetAccentColour(User? user) async {
    SettingsService().updateAccentColour(userId: user?.uid, newValue: '0xFF7E6BFF').then(
          (_) => showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Accent colour reset'),
              content: const Text('A restart may be required for the change to take effect.'),
              actions: [
                TextButton(
                  child: const Text('Ok'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        );
  }

  void goToQuickStart() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QuickStartScreen(),
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
        padding: const EdgeInsets.only(top: 12, bottom: 18, left: 12, right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "About you",
                  style: titleStyle,
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
                        color: AppColors.accentColour,
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
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      (user != null &&
                              user.providerData.map((e) => e.providerId).contains('password'))
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: OutlinedButton(
                                onPressed: () => showResetPasswordDialog(user.email),
                                child: Text(
                                  'Reset password',
                                  style: TextStyle(fontSize: 14, color: AppColors.accentColour),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : const SizedBox(),
                      (user != null && !user.isAnonymous)
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: ElevatedButton(
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Logout'),
                                    content: const Text('Are you sure you want to logout?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('No'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          AuthenticationService().logout().then(
                                                (value) => Navigator.pushAndRemoveUntil(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => const LoginScreen(),
                                                  ),
                                                  (Route<dynamic> route) => false,
                                                ),
                                              );
                                        },
                                        child: const Text('Yes'),
                                      ),
                                    ],
                                  ),
                                ),
                                child: const Text(
                                  'Logout',
                                  style: TextStyle(fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : const SizedBox(),
                      ElevatedButton(
                        onPressed: () => showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                  title: const Text('Delete account'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text(
                                          'Are you sure you want to delete your account and all the data related to it?'),
                                      SizedBox(height: 12),
                                      Text.rich(TextSpan(text: 'This action is ', children: [
                                        TextSpan(
                                          text: 'PERMANENT',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.sortaRed),
                                        ),
                                        TextSpan(text: ' and cannot be undone.')
                                      ])),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('No'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        AuthenticationService().deleteAccount().then(
                                              (value) => Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => const LoginScreen(),
                                                ),
                                                (Route<dynamic> route) => false,
                                              ),
                                            );
                                      },
                                      child: const Text('Yes'),
                                    ),
                                  ],
                                )),
                        child: const Text("Delete account"),
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(AppColors.sortaRed)),
                      )
                    ])),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Aesthetics ✨",
                  style: titleStyle,
                ),
                const SizedBox(height: 18),
                StreamBuilder(
                  stream: SettingsService().streamSettings(user?.uid),
                  builder: (context, AsyncSnapshot<UserSettings> snapshot) {
                    if (snapshot.hasData) {
                      return Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Accent Colour",
                                  style: TextStyle(fontSize: 18),
                                ),
                                const SizedBox(height: 6),
                                FormBuilderColorPickerField(
                                  key: _accentColourFieldKey,
                                  name: "Accent Colour",
                                  initialValue: Color(int.parse(snapshot.data!.accentColour)),
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.required(),
                                    (val) {
                                      if (val?.alpha != 255) {
                                        return "Please select a fully opaque colour";
                                      }
                                      if ('0x${val.toString().substring(8, 16).toUpperCase()}' ==
                                          snapshot.data!.accentColour) {
                                        return "This is already your accent colour";
                                      }
                                      return null;
                                    }
                                  ]),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                        onPressed: () => resetAccentColour(user),
                                        child: const Text("Reset to default")),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                        onPressed: () => updateAccentColour(user),
                                        child: const Text("Apply"))
                                  ],
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          SettingsRadioCard(
                            title: "ETA Format",
                            initialValue: snapshot.data!.isETAminutes,
                            firebaseFieldName: 'isETAminutes',
                            options: [
                              SettingsCardOption(value: true, text: "Minutes to arrival (2 mins)"),
                              SettingsCardOption(value: false, text: "Time of arrival (18:21)")
                            ],
                          ),
                          const SizedBox(height: 18),
                          SettingsRadioCard(
                            title: "Nearby Layout",
                            initialValue: snapshot.data!.isNearbyGrid,
                            firebaseFieldName: 'isNearbyGrid',
                            options: [
                              SettingsCardOption(value: true, text: "Grid layout"),
                              SettingsCardOption(value: false, text: "Column layout")
                            ],
                          ),
                          const SizedBox(height: 18),
                          SettingsRadioCard(
                              title: "Nearby Detail",
                              initialValue: snapshot.data!.showNearbyDistance ?? true,
                              firebaseFieldName: 'showNearbyDistance',
                              options: [
                                SettingsCardOption(value: true, text: "Distance to bus stops"),
                                SettingsCardOption(value: false, text: "Road name of bus stops")
                              ]),
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
                      return const Center(child: CircularProgressIndicator(strokeWidth: 3));
                    }
                  },
                )
              ],
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Others",
                  style: titleStyle,
                ),
                const SizedBox(height: 18),
                Material(
                  child: InkWell(
                    onTap: () => goToQuickStart(),
                    customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Ink(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            "View Quick Start",
                            style: TextStyle(fontSize: 18),
                          ),
                          Icon(
                            Icons.description_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Material(
                  child: InkWell(
                    onTap: () => showAboutDialog(
                        context: context,
                        applicationIcon: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            "assets/icons/Icon-1024x1024.png",
                            width: 56,
                            height: 56,
                          ),
                        ),
                        applicationName: "Transito",
                        applicationVersion: "1.2.2",
                        applicationLegalese: "© 2022 Transito",
                        children: const [
                          SizedBox(height: 18),
                          Text(
                            "Bus arrival data is provided via Land Transport Authority's (LTA) datasets.",
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Transito is not responsible for any inaccuracies in the data.",
                            style: TextStyle(fontSize: 14),
                          ),
                        ]),
                    customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Ink(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              "About",
                              style: TextStyle(fontSize: 18),
                            ),
                            Icon(
                              Icons.info_outline_rounded,
                            ),
                          ],
                        )),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
