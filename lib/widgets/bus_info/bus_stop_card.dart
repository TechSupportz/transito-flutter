import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/search_provider.dart';
import 'package:transito/models/api/transito/bus_routes.dart';
import 'package:transito/models/api/transito/bus_stops.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/screens/bus_info/bus_stop_info_screen.dart';
import 'package:transito/screens/bus_info/bus_timing_screen.dart';

class BusStopCard extends StatelessWidget {
  const BusStopCard({
    super.key,
    required this.busStopInfo,
    this.showDistanceFromUser = false,
    this.distanceFromUser,
    this.searchMode = false,
    this.routeMode = false,
    this.busSchedule,
  });

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

  Widget busScheduleDialog(BuildContext context) {
    String currentDay = Jiffy.now().format(pattern: "E");
    int selectedDay = currentDay == "Sat"
        ? 1
        : currentDay == "Sun"
            ? 2
            : 0;

    const TextStyle titleStyle = TextStyle(
      fontWeight: FontWeight.w400,
      color: AppColors.kindaGrey,
      fontFamily: 'Poppins',
      fontSize: 18.0,
    );

    const TextStyle timeStyle = TextStyle(
      fontWeight: FontWeight.w600,
      fontFamily: 'Poppins',
      fontSize: 30.0,
    );

    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text('Bus Schedule'),
            const SizedBox(height: 4.0),
            Wrap(spacing: 6.0, children: [
              ChoiceChip(
                label: const Text("Weekday"),
                selected: selectedDay == 0,
                onSelected: (selected) {
                  setState(() {
                    selectedDay = 0;
                  });
                },
                selectedColor: AppColors.accentColour.withOpacity(0.5),
              ),
              ChoiceChip(
                label: const Text("Saturday"),
                selected: selectedDay == 1,
                onSelected: (selected) {
                  setState(() {
                    selectedDay = 1;
                  });
                },
                selectedColor: AppColors.accentColour.withOpacity(0.5),
              ),
              ChoiceChip(
                label: const Text("Sunday"),
                selected: selectedDay == 2,
                onSelected: (selected) {
                  setState(() {
                    selectedDay = 2;
                  });
                },
                selectedColor: AppColors.accentColour.withOpacity(0.5),
              ),
            ]),
          ],
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.light_mode_rounded,
                        size: 24,
                      ),
                      SizedBox(width: 6.0),
                      Text(
                        "First Bus",
                        style: titleStyle,
                      )
                    ],
                  ),
                  if (selectedDay == 0 && busSchedule!.firstBus.weekdays != "-:")
                    Text(
                      Jiffy.parse(
                        busSchedule!.firstBus.weekdays,
                        pattern: 'Hm',
                      ).jm,
                      style: timeStyle,
                    )
                  else if (selectedDay == 1 && busSchedule!.firstBus.saturday != "-:")
                    Text(
                      Jiffy.parse(
                        busSchedule!.firstBus.saturday,
                        pattern: 'Hm',
                      ).jm,
                      style: timeStyle,
                    )
                  else if (selectedDay == 2 && busSchedule!.firstBus.sunday != "-:")
                    Text(
                      Jiffy.parse(
                        busSchedule!.firstBus.sunday,
                        pattern: 'Hm',
                      ).jm,
                      style: timeStyle,
                    )
                  else
                    const Text(
                      "never o'clock",
                      style: timeStyle,
                    ),
                ],
              ),
              const SizedBox(height: 8.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.nights_stay_rounded, size: 24),
                      SizedBox(width: 6.0),
                      Text(
                        "Last Bus",
                        style: titleStyle,
                      )
                    ],
                  ),
                  if (selectedDay == 0 && busSchedule!.lastBus.weekdays != "-:")
                    Text(
                      Jiffy.parse(
                        busSchedule!.lastBus.weekdays,
                        pattern: 'Hm',
                      ).jm,
                      style: timeStyle,
                    )
                  else if (selectedDay == 1 && busSchedule!.lastBus.saturday != "-:")
                    Text(
                      Jiffy.parse(
                        busSchedule!.lastBus.saturday,
                        pattern: 'Hm',
                      ).jm,
                      style: timeStyle,
                    )
                  else if (selectedDay == 2 && busSchedule!.lastBus.sunday != "-:")
                    Text(
                      Jiffy.parse(
                        busSchedule!.lastBus.sunday,
                        pattern: 'Hm',
                      ).jm,
                      style: timeStyle,
                    )
                  else
                    const Text(
                     "never o'clock",
                      style: timeStyle,
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
        actionsPadding: const EdgeInsets.only(bottom: 8.0, right: 16.0),
      ),
    );
  }
}
