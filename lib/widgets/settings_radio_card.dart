import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:transito/models/app_colors.dart';
import 'package:transito/models/settings_card_options.dart';

import '../providers/settings_service.dart';

class SettingsRadioCard extends StatelessWidget {
  const SettingsRadioCard(
      {Key? key,
      required this.title,
      required this.initialValue,
      required this.firebaseFieldName,
      required this.options})
      : super(key: key);

  final String title;
  final bool initialValue;
  final String firebaseFieldName;
  final List<SettingsCardOption> options;

  final TextStyle titleStyle = const TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w500,
  );

  final TextStyle optionTextStyle = const TextStyle(
    fontSize: 18,
  );

  @override
  Widget build(BuildContext context) {
    User? user = context.watch<User?>();

    void updateSettings(bool newValue) {
      switch (firebaseFieldName) {
        case 'isETAminutes':
          SettingsService().updateIsETAminutes(
            userId: user?.uid,
            newValue: newValue,
          );
          break;
        case 'isNearbyGrid':
          SettingsService().updateIsNearbyGrid(
            userId: user?.uid,
            newValue: newValue,
          );
          break;
        case 'showNearbyDistance':
          SettingsService().updateShowNearbyDistance(
            userId: user?.uid,
            newValue: newValue,
          );
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: titleStyle,
          ),
          const SizedBox(height: 6),
          FormBuilderRadioGroup(
            name: 'radioGroup',
            controlAffinity: ControlAffinity.trailing,
            orientation: OptionsOrientation.vertical,
            activeColor: AppColors.accentColour,
            initialValue: initialValue,
            onChanged: (value) => updateSettings(value as bool),
            options: options
                .map((option) => FormBuilderFieldOption(
                      value: option.value,
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          option.text,
                          style: optionTextStyle,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
