import 'package:flutter/material.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/screens/bus_info/bus_service_info_screen.dart';

class BusServiceChip extends StatelessWidget {
  const BusServiceChip({
    super.key,
    required this.busServiceNumber,
    required this.isOperating,
    this.originStopCode,
    this.currentStopCode,
  });

  final String busServiceNumber;
  final bool isOperating;
  final String? originStopCode;
  final String? currentStopCode;

  Future<void> goToBusServiceInfoScreen(BuildContext context) async {
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusServiceInfoScreen(
          serviceNo: busServiceNumber,
          originStopCode: originStopCode,
          currentStopCode: currentStopCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isOperating ? 1 : 0.5,
      child: InkWell(
        onTap: () => goToBusServiceInfoScreen(context),
        borderRadius: BorderRadius.circular(7.5),
        splashColor: AppColors.accentColour.withOpacity(0.75),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.accentColour, width: 1.5),
            borderRadius: BorderRadius.circular(7.5),
          ),
          child: Text(
            busServiceNumber,
            style: const TextStyle(
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}
