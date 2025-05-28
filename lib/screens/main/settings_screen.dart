import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_extra_fields/form_builder_extra_fields.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:flutter_skeleton_ui/flutter_skeleton_ui.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/models/app/settings_card_options.dart';
import 'package:transito/models/enums/app_theme_mode.dart';
import 'package:transito/models/user/user_settings.dart';
import 'package:transito/global/services/authentication_service.dart';
import 'package:transito/global/services/settings_service.dart';
import 'package:transito/screens/auth/login_screen.dart';
import 'package:transito/screens/navigator_screen.dart';
import 'package:transito/screens/onboarding/quick_start_screen.dart';
import 'package:transito/widgets/common/error_text.dart';
import 'package:transito/widgets/settings/settings_others_card.dart';
import 'package:transito/widgets/settings/settings_radio_card.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameFieldKey = GlobalKey<FormBuilderFieldState>();
  final _accentColourFieldKey = GlobalKey<FormBuilderFieldState>();
  bool _isNameFieldLoading = false;
  final TextStyle titleStyle = const TextStyle(fontSize: 30, fontWeight: FontWeight.w700);
  late Future<PackageInfo> _appInfo;

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
          FilledButton(
            child: const Text('Yes'),
            onPressed: () {
              if (email != null) {
                AuthenticationService().sendPasswordResetEmail(email).then((_) {
                  Navigator.of(context).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                      settings: const RouteSettings(name: 'LoginScreen'),
                    ),
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
      Color newColour = _accentColourFieldKey.currentState!.value as Color;

      SettingsService()
          .updateAccentColour(
            userId: user.uid,
            newValue: '0x${newColour.value.toRadixString(16).toUpperCase()}',
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
                            builder: (context) => const NavigatorScreen(),
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
                        builder: (context) => const NavigatorScreen(),
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

  Future<PackageInfo> getAppInfo() async {
    print("Fetching App Info...");
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo;
  }

  void goToQuickStart() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QuickStartScreen(),
        settings: const RouteSettings(name: 'QuickStartScreen'),
      ),
    );
  }

  // initializes the screen
  @override
  void initState() {
    super.initState();
    _appInfo = getAppInfo();
  }

  @override
  Widget build(BuildContext context) {
    User? user = context.watch<User?>();
    AppColors appColors = context.watch<AppColors>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 12, bottom: 16, left: 12, right: 12),
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
                const SizedBox(height: 16),
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
                        borderRadius: BorderRadius.circular(12),
                        color: appColors.scheme.primary,
                      ),
                      child: AnimatedSwitcher(
                          transitionBuilder: (child, animation) => ScaleTransition(
                                scale: animation,
                                child: child,
                              ),
                          duration: const Duration(milliseconds: 175),
                          child: _isNameFieldLoading
                              ? SizedBox(
                                  // height: 16,
                                  // width: 16,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: appColors.scheme.onPrimary,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  splashRadius: 1,
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    updateDisplayName(user);
                                  },
                                  icon: Icon(
                                    Icons.check_rounded,
                                    size: 21,
                                    color: appColors.scheme.onPrimary,
                                  ),
                                )),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      (user != null &&
                              user.providerData.map((e) => e.providerId).contains('password'))
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: FilledButton.tonal(
                                onPressed: () => showResetPasswordDialog(user.email),
                                child: Text(
                                  'Reset password',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : const SizedBox(),
                      (user != null && !user.isAnonymous)
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: FilledButton(
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
                                                    settings:
                                                        const RouteSettings(name: 'LoginScreen'),
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
                      FilledButton(
                        onPressed: () => showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                  title: const Text('Delete account'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                          'Are you sure you want to delete your account and all the data related to it?'),
                                      const SizedBox(height: 12),
                                      Text.rich(TextSpan(text: 'This action is ', children: [
                                        TextSpan(
                                          text: 'PERMANENT',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.error),
                                        ),
                                        const TextSpan(text: ' and cannot be undone.')
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
                                        AuthenticationService().deleteAccount();
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const LoginScreen(),
                                            settings: const RouteSettings(name: 'LoginScreen'),
                                          ),
                                          (Route<dynamic> route) => false,
                                        );
                                      },
                                      child: const Text('Yes'),
                                    ),
                                  ],
                                )),
                        style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(appColors.scheme.error)),
                        child: Text(
                          "Delete account",
                          style: TextStyle(color: appColors.scheme.onError),
                        ),
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
                const SizedBox(height: 16),
                StreamBuilder(
                  stream: SettingsService().streamSettings(user?.uid),
                  builder: (context, AsyncSnapshot<UserSettings> snapshot) {
                    if (snapshot.hasData) {
                      return Column(
                        spacing: 16,
                        children: [
                          SettingsRadioCard<AppThemeMode>(
                            title: "Theme",
                            initialValue: snapshot.data!.themeMode,
                            firebaseFieldName: 'themeMode',
                            options: [
                              SettingsCardOption(value: AppThemeMode.LIGHT, label: "Light"),
                              SettingsCardOption(value: AppThemeMode.DARK, label: "Dark"),
                              SettingsCardOption(
                                  value: AppThemeMode.SYSTEM, label: "Follow System"),
                            ],
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            decoration: BoxDecoration(
                              color: appColors.scheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              spacing: 8,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Base Colour",
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                FormBuilderColorPickerField(
                                  key: _accentColourFieldKey,
                                  name: "Accent Colour",
                                  colorPickerType: ColorPickerType.colorPicker,
                                  colorPreviewBuilder: (p0) => Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Container(
                                      width: 40,
                                      decoration: BoxDecoration(
                                        color: p0,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  initialValue: Color(int.parse(snapshot.data!.accentColour)),
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  keyboardType: TextInputType.none,
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.required(),
                                    (val) {
                                      if (val?.a != 1) {
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    FilledButton.tonal(
                                        onPressed: () => resetAccentColour(user),
                                        child: const Text("Reset to default")),
                                    const SizedBox(width: 8),
                                    FilledButton(
                                        onPressed: () => updateAccentColour(user),
                                        child: const Text("Apply"))
                                  ],
                                )
                              ],
                            ),
                          ),
                          SettingsRadioCard<bool>(
                            title: "ETA Format",
                            initialValue: snapshot.data!.isETAminutes,
                            firebaseFieldName: 'isETAminutes',
                            options: [
                              SettingsCardOption(value: true, label: "Minutes to arrival (2 mins)"),
                              SettingsCardOption(value: false, label: "Time of arrival (18:21)")
                            ],
                          ),
                          SettingsRadioCard<bool>(
                            title: "Nearby Layout",
                            initialValue: snapshot.data!.isNearbyGrid,
                            firebaseFieldName: 'isNearbyGrid',
                            options: [
                              SettingsCardOption(value: true, label: "Grid layout"),
                              SettingsCardOption(value: false, label: "Column layout")
                            ],
                          ),
                          SettingsRadioCard<bool>(
                              title: "Nearby Detail",
                              initialValue: snapshot.data!.showNearbyDistance,
                              firebaseFieldName: 'showNearbyDistance',
                              options: [
                                SettingsCardOption(value: true, label: "Distance to bus stops"),
                                SettingsCardOption(value: false, label: "Road name of bus stops")
                              ]),
                        ],
                      );
                    } else if (snapshot.hasError) {
                      return Container(
                          decoration: BoxDecoration(
                            color: appColors.scheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
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
                const SizedBox(height: 16),
                SettingsOthersCard(
                  title: "View Quick Start",
                  icon: Icons.description_rounded,
                  onTap: () => goToQuickStart(),
                ),
                const SizedBox(height: 16),
                SettingsOthersCard(
                  title: "Feedback Form",
                  icon: Icons.feedback_rounded,
                  onTap: () => launchUrl(
                    Uri.parse("https://transito.tnitish.com/feedback"),
                    mode: LaunchMode.inAppWebView,
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder(
                    future: _appInfo,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        print(snapshot.data);
                        return SettingsOthersCard(
                          title: "About",
                          icon: Icons.info_outline_rounded,
                          onTap: () => showAboutDialog(
                              context: context,
                              applicationIcon: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  "assets/icons/Icon-1024x1024.png",
                                  width: 64,
                                  height: 64,
                                ),
                              ),
                              applicationName: "Transito",
                              applicationVersion: "v${snapshot.data!.version}",
                              applicationLegalese: "© 2023 Transito",
                              children: const [
                                SizedBox(height: 16),
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
                        );
                      } else if (snapshot.hasError) {
                        print(snapshot.error);
                      }
                      return SkeletonItem(
                          child: SkeletonLine(
                        style: SkeletonLineStyle(
                          height: 45,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ));
                    })
              ],
            )
          ],
        ),
      ),
    );
  }
}
