import 'package:flutter/material.dart';
import 'package:transito/models/app/app_typography.dart';
import 'package:transito/screens/bus_info/bus_service_info_screen.dart';

class BusServiceChip extends StatelessWidget {
  const BusServiceChip({
    super.key,
    required this.busServiceNumber,
    required this.isOperating,
    this.originStopCode,
    this.destinationStopCode,
    this.currentStopCode,
  });

  final String busServiceNumber;
  final bool isOperating;
  final String? originStopCode;
  final String? destinationStopCode;
  final String? currentStopCode;

  Future<void> goToBusServiceInfoScreen(BuildContext context) async {
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusServiceInfoScreen(
          serviceNo: busServiceNumber,
          originStopCode: originStopCode,
          destinationStopCode: destinationStopCode,
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
        borderRadius: BorderRadius.circular(12),
        splashColor: isOperating
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)
            : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 0.5),
          decoration: BoxDecoration(
            border: Border.all(
              color: isOperating
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            busServiceNumber,
            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
