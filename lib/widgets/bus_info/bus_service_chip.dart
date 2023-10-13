import 'package:flutter/material.dart';
import 'package:transito/models/app/app_colors.dart';

class BusServiceChip extends StatelessWidget {
  const BusServiceChip({Key? key, required this.busServiceNumber}) : super(key: key);

  final String busServiceNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
