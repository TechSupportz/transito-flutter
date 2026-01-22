import 'package:flutter/material.dart';
import 'package:transito/models/app/app_colors.dart';

/// Displays a warning snackbar indicating that bus timings may be unavailable
/// due to LTA scheduled system maintenance
void showLtaMaintenanceWarningSnackbar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.fixed,
      backgroundColor: AppColors().scheme.error,
      showCloseIcon: true,
      duration: const Duration(seconds: 6),
      content: Row(
        children: [
          Text(
            "!!!",
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900, color: AppColors().scheme.onError),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text.rich(
              style: TextStyle(color: AppColors().scheme.onError),
              softWrap: true,
              overflow: TextOverflow.visible,
              const TextSpan(
                text:
                    "Bus timings may be temporarily unavailable due to system maintenance by LTA",
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
