import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:transito/models/app_colors.dart';

class SettingsOthersCard extends StatelessWidget {
  const SettingsOthersCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  final String title;
  final IconData icon;
  final void Function() onTap;

  final TextStyle titleTextStyle = const TextStyle(
    fontSize: 18,
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: onTap,
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
            children: [
              Text(title, style: titleTextStyle),
              Icon(icon),
            ],
          ),
        ),
      ),
    );
  }
}
