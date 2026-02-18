import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:transito/global/providers/common_provider.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/widgets/common/app_symbol.dart';

/// Displays a warning snackbar indicating that bus timings may be unavailable
/// due to LTA scheduled system maintenance
void showLtaMaintenanceWarningSnackbar() {
  final scaffoldMessenger = CommonProvider.scaffoldMessengerKey.currentState;
  if (scaffoldMessenger == null) return;
  scaffoldMessenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.fixed,
      backgroundColor: AppColors().scheme.error,
      showCloseIcon: true,
      duration: const Duration(seconds: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      content: Row(
        children: [
          AppSymbol(
            Symbols.bus_alert_rounded,
            size: 26,
            color: AppColors().scheme.onError,
            fill: true,
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              "LTA's not talking to us right now...\nBus timings may be unavailable",
              style: TextStyle(color: AppColors().scheme.onError),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    ),
  );
}
