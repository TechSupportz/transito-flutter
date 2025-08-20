import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:transito/models/app/settings_card_options.dart';
import 'package:transito/models/enums/app_theme_mode_enum.dart';

import '../../global/services/settings_service.dart';

class SettingsRadioCard<T> extends StatelessWidget {
  const SettingsRadioCard(
      {super.key,
      required this.title,
      required this.initialValue,
      required this.firebaseFieldName,
      required this.options});

  final String title;
  final T initialValue;
  final String firebaseFieldName;
  final List<SettingsCardOption<T>> options;

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

    void updateSettings(T newValue) {
      switch (firebaseFieldName) {
        case 'isETAminutes':
          SettingsService().updateIsETAminutes(
            userId: user?.uid,
            newValue: newValue as bool,
          );
          break;
        case 'isNearbyGrid':
          SettingsService().updateIsNearbyGrid(
            userId: user?.uid,
            newValue: newValue as bool,
          );
          break;
        case 'showNearbyDistance':
          SettingsService().updateShowNearbyDistance(
            userId: user?.uid,
            newValue: newValue as bool,
          );
          break;
        case 'themeMode':
          SettingsService().updateThemeMode(
            userId: user?.uid,
            newValue: newValue as AppThemeMode,
            context: context,
          );
        // Add more cases as needed for other field types
        default:
          // Handle generic case or throw error
          break;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(title, style: titleStyle),
          FormBuilderRadioGroup<T>(
            name: firebaseFieldName,
            initialValue: initialValue,
            orientation: OptionsOrientation.vertical,
            onChanged: (T? value) {
              if (value != null) {
                updateSettings(value);
              }
            },
            activeColor: Theme.of(context).colorScheme.primary,
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(12),
                ),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            ),
            options: options
                .map((option) => FormBuilderFieldOption(
                      value: option.value,
                      child: Text(option.label, style: optionTextStyle),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
