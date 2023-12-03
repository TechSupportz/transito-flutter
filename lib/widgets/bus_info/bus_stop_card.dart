import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:transito/models/api/transito/bus_stops.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/global/providers/search_provider.dart';
import 'package:transito/screens/bus_info/bus_stop_info_screen.dart';
import 'package:transito/screens/bus_info/bus_timing_screen.dart';

class BusStopCard extends StatelessWidget {
  const BusStopCard(
      {Key? key,
      required this.busStopInfo,
      this.distanceFromUser,
      this.searchMode = false,
      this.showDistanceFromUser = false})
      : super(key: key);

  final BusStop busStopInfo;
  final double? distanceFromUser;
  final bool showDistanceFromUser;
  final bool searchMode;

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
            if (searchMode) {
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
                          color: AppColors.accentColour, borderRadius: BorderRadius.circular(5)),
                      child: Text(
                        busStopInfo.code,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        searchMode
                            ? busStopInfo.roadName
                            : showDistanceFromUser
                                ? '${transformDistanceFromUser(distanceFromUser!)} away'
                                : busStopInfo.roadName,
                        overflow: TextOverflow.fade,
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(
                            color: AppColors.kindaGrey, fontStyle: FontStyle.italic),
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
