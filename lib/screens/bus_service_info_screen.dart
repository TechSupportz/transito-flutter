import 'package:flutter/material.dart';

import '../models/app_colors.dart';
import '../models/bus_services.dart';
import '../models/enums/bus_operator_enum.dart';

class BusServiceInfoScreen extends StatelessWidget {
  const BusServiceInfoScreen({
    Key? key,
    required this.busServiceInfo,
  }) : super(key: key);

  final BusServiceInfo busServiceInfo;

  // function that returns the correct colours for each bus operator
  Color getOperatorColor(BusOperator operator) {
    switch (operator) {
      case BusOperator.SBST:
        return AppColors.SBST;
      case BusOperator.SMRT:
        return AppColors.SMRT;
      case BusOperator.TTS:
        return AppColors.TTS;
      case BusOperator.GAS:
        return AppColors.GAS;
      default:
        return AppColors.accentColour;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Service Info'),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bus ${busServiceInfo.serviceNo}',
                  overflow: TextOverflow.fade,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                      color: getOperatorColor(busServiceInfo.operator),
                      borderRadius: BorderRadius.circular(5)),
                  child: Text(busServiceInfo.operator.name,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Dispatch Frequency",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.cardBg,
                  ),
                  child: Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    defaultColumnWidth: const FixedColumnWidth(250),
                    children: [
                      const TableRow(
                        children: [
                          Text('Time', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600)),
                          Text('Minutes',
                              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Text('6:30am - 8:30am', style: TextStyle(fontSize: 21)),
                          Text(busServiceInfo.AMPeakFreq, style: const TextStyle(fontSize: 21)),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Text('8:31am - 4:59pm', style: TextStyle(fontSize: 21)),
                          Text(busServiceInfo.AMOffPeakFreq, style: const TextStyle(fontSize: 21)),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Text('5:00pm - 7:00pm', style: TextStyle(fontSize: 21)),
                          Text(busServiceInfo.PMPeakFreq, style: const TextStyle(fontSize: 21)),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Text('After 7:00pm', style: TextStyle(fontSize: 21)),
                          Text(busServiceInfo.PMOffPeakFreq, style: const TextStyle(fontSize: 21)),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
