import 'package:flutter/material.dart';
import 'package:transito/models/api/transito/bus_stops.dart';
import 'package:transito/models/app/app_colors.dart';

class BasicBusStopCard extends StatelessWidget {
  const BasicBusStopCard({super.key, required this.busStop});

  final SimpleBusStop busStop;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            busStop.name,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
                color: AppColors.accentColour, borderRadius: BorderRadius.circular(5)),
            child: Text(
              busStop.code,
            ),
          ),
        ],
      ),
    );
  }
}
