import 'package:flutter/material.dart';
import 'package:transito/models/app_colors.dart';

import '../models/bus_stops.dart';
import '../screens/bus_timing_screen.dart';

class BusStopCard extends StatelessWidget {
  const BusStopCard({Key? key, required this.busStopInfo}) : super(key: key);

  final BusStopInfo busStopInfo;

  void goToBusTimingScreen(BuildContext context, String busStopCode, String busStopName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusTimingScreen(
          busStopCode: busStopCode,
          busStopName: busStopName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: busStopInfo.busStopName,
        child: InkWell(
          onTap: () =>
              goToBusTimingScreen(context, busStopInfo.busStopCode, busStopInfo.busStopName),
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Ink(
            decoration:
                BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    busStopInfo.busStopName,
                    overflow: TextOverflow.fade,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                          color: AppColors.veryPurple, borderRadius: BorderRadius.circular(5)),
                      child: Text(
                        busStopInfo.busStopCode,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        busStopInfo.roadName,
                        overflow: TextOverflow.fade,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(color: AppColors.kindaGrey, fontStyle: FontStyle.italic),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
