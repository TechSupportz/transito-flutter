import 'package:flutter/material.dart';
import 'package:transito/widgets/common/app_symbol.dart';

class SettingsOthersCard extends StatelessWidget {
  const SettingsOthersCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final AppSymbol icon;
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
          borderRadius: BorderRadius.circular(12),
        ),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: titleTextStyle),
              icon,
            ],
          ),
        ),
      ),
    );
  }
}
