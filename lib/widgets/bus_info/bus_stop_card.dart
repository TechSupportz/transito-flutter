import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:transito/models/api/transito/bus_routes.dart';
import 'package:transito/models/api/transito/bus_stops.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/global/providers/search_provider.dart';
import 'package:transito/screens/bus_info/bus_stop_info_screen.dart';
import 'package:transito/screens/bus_info/bus_timing_screen.dart';

class BusStopCard extends StatelessWidget {
  const BusStopCard({
    Key? key,
    required this.busStopInfo,
    this.showDistanceFromUser = false,
    this.distanceFromUser,
    this.searchMode = false,
    this.routeMode = false,
    this.busSchedule,
  }) : super(key: key);

  final BusStop busStopInfo;
  final double? distanceFromUser;
  final bool showDistanceFromUser;
  final bool searchMode;
  final bool routeMode;
  final ({BusSchedule firstBus, BusSchedule lastBus})? busSchedule;

  // function that navigates user to bus timing screen
  void goToBusTimingScreen(
    BuildContext context,
    String code,
    String name,
    String address,
    List<String>? services,
    LatLng busStopLocation,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusTimingScreen(
          code: code,
          name: name,
          address: address,
          services: services,
          busStopLocation: busStopLocation,
        ),
        settings: const RouteSettings(name: 'BusTimingScreen'),
      ),
    );
  }

  void goToBusStopInfoScreen(
    BuildContext context,
    String code,
    String name,
    String address,
    List<String>? services,
    LatLng busStopLocation,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusStopInfoScreen(
          code: code,
          name: name,
          address: address,
          services: services,
          busStopLocation: busStopLocation,
        ),
        settings: const RouteSettings(name: 'BusStopInfoScreen'),
      ),
    );
  }

  String transformDistanceFromUser(double distance) {
    if (distance < 1000) {
      return '${(distance).toStringAsFixed(0)}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        preferBelow: false,
        showDuration: const Duration(milliseconds: 350),
        message: busStopInfo.name,
        child: InkWell(
          onTap: () {
            if (searchMode || routeMode) {
              searchProvider.addRecentSearch(busStopInfo);
              goToBusStopInfoScreen(
                context,
                busStopInfo.code,
                busStopInfo.name,
                busStopInfo.roadName,
                busStopInfo.services,
                LatLng(busStopInfo.latitude, busStopInfo.longitude),
              );
            } else {
              goToBusTimingScreen(
                context,
                busStopInfo.code,
                busStopInfo.name,
                busStopInfo.roadName,
                busStopInfo.services,
                LatLng(busStopInfo.latitude, busStopInfo.longitude),
              );
            }
          },
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Ink(
            decoration:
                BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        busStopInfo.name,
                        overflow: TextOverflow.fade,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: searchMode ? 24 : 21,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: searchMode ? 4 : 0),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                                color: AppColors.accentColour,
                                borderRadius: BorderRadius.circular(5)),
                            child: Text(busStopInfo.code),
                          ),
                          Expanded(
                            child: Text(
                              (searchMode || !showDistanceFromUser)
                                  ? busStopInfo.roadName
                                  : '${transformDistanceFromUser(distanceFromUser!)} away',
                              overflow: TextOverflow.fade,
                              maxLines: 1,
                              softWrap: false,
                              style: const TextStyle(
                                  color: AppColors.kindaGrey, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                if (routeMode && busSchedule != null) ...[
                  IconButton(
                    splashRadius: 20,
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => busScheduleDialog(context),
                    ),
                    icon: const Icon(Icons.info_outline_rounded),
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  AlertDialog busScheduleDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('Bus Schedule'),
      insetPadding: const EdgeInsets.all(16),
      content: SizedBox(
        width: double.maxFinite,
        child: Table(
          children: [
            TableRow(
              children: [
                TableCell(
                  child: Container(),
                ),
                const TableCell(
                  child: Text("First Bus"),
                ),
                const TableCell(
                  child: Text("Last Bus"),
                )
              ],
            ),
            TableRow(
              children: [
                const TableCell(
                  child: Text("Weekdays"),
                ),
                TableCell(
                  child: Text(busSchedule!.firstBus.weekdays),
                ),
                TableCell(
                  child: Text(busSchedule!.lastBus.weekdays),
                )
              ],
            ),
            TableRow(
              children: [
                const TableCell(
                  child: Text("Saturday"),
                ),
                TableCell(
                  child: Text(busSchedule!.firstBus.saturday),
                ),
                TableCell(
                  child: Text(busSchedule!.lastBus.saturday),
                )
              ],
            ),
            TableRow(
              children: [
                const TableCell(
                  child: Text("Sunday"),
                ),
                TableCell(
                  child: Text(busSchedule!.firstBus.sunday),
                ),
                TableCell(
                  child: Text(busSchedule!.lastBus.sunday),
                )
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        )
      ],
    );
  }
}
