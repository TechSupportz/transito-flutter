import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:transito/models/app_colors.dart';
import 'package:transito/models/settings_card_options.dart';

class SettingsRadioCard extends StatelessWidget {
  const SettingsRadioCard(
      {Key? key, required this.title, required this.initialValue, required this.options})
      : super(key: key);

  final String title;
  final bool initialValue;
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
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
            activeColor: AppColors.veryPurple,
            initialValue: initialValue,
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
