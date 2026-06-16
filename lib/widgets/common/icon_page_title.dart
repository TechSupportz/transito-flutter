import 'package:flutter/material.dart';
import 'package:transito/models/app/app_typography.dart';
import 'package:transito/widgets/common/app_symbol.dart';

class IconPageTitle extends StatelessWidget {
  const IconPageTitle({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.screenHeading,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, right: 4),
          child: AppSymbol(
            icon,
            fill: true,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
