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
        return AppColors.veryPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Service Info'),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 16.0),
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
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                  margin: EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                      color: getOperatorColor(busServiceInfo.operator),
                      borderRadius: BorderRadius.circular(5)),
                  child: Text(busServiceInfo.operator.name,
                      style: TextStyle(fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dispatch Frequency",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.cardBg,
                  ),
                  child: Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    defaultColumnWidth: FixedColumnWidth(250),
                    children: [
                      TableRow(
                        children: [
                          Text('Time', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600)),
                          Text('Minutes',
                              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      TableRow(
                        children: [
                          Text('6:30am - 8:30am', style: TextStyle(fontSize: 21)),
                          Text('${busServiceInfo.AMPeakFreq}', style: TextStyle(fontSize: 21)),
                        ],
                      ),
                      TableRow(
                        children: [
                          Text('8:31am - 4:59pm', style: TextStyle(fontSize: 21)),
                          Text('${busServiceInfo.AMOffPeakFreq}', style: TextStyle(fontSize: 21)),
                        ],
                      ),
                      TableRow(
                        children: [
                          Text('5:00pm - 7:00pm', style: TextStyle(fontSize: 21)),
                          Text('${busServiceInfo.PMPeakFreq}', style: TextStyle(fontSize: 21)),
                        ],
                      ),
                      TableRow(
                        children: [
                          Text('After 7:00pm', style: TextStyle(fontSize: 21)),
                          Text('${busServiceInfo.PMOffPeakFreq}', style: TextStyle(fontSize: 21)),
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
