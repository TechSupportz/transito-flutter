import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';

class EmailVerificationDialog extends StatelessWidget {
  const EmailVerificationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    void openMailApp() {
      if (Platform.isAndroid) {
        AndroidIntent intent = const AndroidIntent(
          action: 'android.intent.action.MAIN',
          category: 'android.intent.category.APP_EMAIL',
          flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        intent.launch();
      }
      Navigator.of(context).pop();
    }

    return AlertDialog(
      title: const Text('Verify your email'),
      content: const Text(
          'Please check your email and click on the link to verify your account, before proceeding to login.'),
      actions: [
        TextButton(
          child: const Text('Ok'),
          onPressed: () => openMailApp(),
        ),
      ],
    );
  }
}
