import 'package:flutter/material.dart';
import 'package:transito/models/app/app_colors.dart';

class ErrorText extends StatelessWidget {
  const ErrorText({super.key, this.enableBackground = false});

  final bool enableBackground;

  @override
  Widget build(BuildContext context) {
    Widget errorText = const Center(
      child: Column(
        children: [
          Text(
            'Oops something went wrong',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Restarting the app might help',
            style: TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );

    if (enableBackground) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: errorText,
          ),
        ),
      );
    }

    return errorText;
  }
}
