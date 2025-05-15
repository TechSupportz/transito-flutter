import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jiffy/jiffy.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_skeleton_ui/flutter_skeleton_ui.dart';
import 'package:transito/models/api/lta/arrival_info.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/models/secret.dart';
import 'package:transito/models/user/user_settings.dart';
import 'package:transito/global/services/settings_service.dart';
import 'package:transito/screens/bus_info/bus_timing_screen.dart';
import 'package:transito/widgets/bus_timings/bus_timing_row.dart';
import 'package:transito/widgets/common/error_text.dart';

class FavouritesTimingCard extends StatefulWidget {
  const FavouritesTimingCard({
    super.key,
    required this.code,
    required this.name,
    required this.address,
    required this.services,
    required this.busStopLocation,
  });

  final String code;
  final String name;
  final String address;
  final List<String?> services;
  final LatLng busStopLocation;

  @override
  State<FavouritesTimingCard> createState() => _FavouritesTimingCardState();
}

class _FavouritesTimingCardState extends State<FavouritesTimingCard> {
  late Future<List<ServiceInfo>> futureBusArrivalInfo;
  late Timer timer;

  // api request headers
  Map<String, String> requestHeaders = {
    'Accept': 'application/json',
    'AccountKey': Secret.LTA_API_KEY
  };

  // function to fetch bus arrival info
  Future<BusArrivalInfo> fetchArrivalTimings() async {
    debugPrint("Fetching favourite arrival timings");
    // gets response from api
    final response = await http.get(
        Uri.parse(
            'https://datamall2.mytransport.sg/ltaodataservice/v3/BusArrival?BusStopCode=${widget.code}'),
        headers: requestHeaders);

    // if response is successful, parse the response and return it as a BusArrivalInfo object
    if (response.statusCode == 200) {
      debugPrint("Favourites Timing fetched");
      return BusArrivalInfo.fromJson(jsonDecode(response.body));
    } else {
      debugPrint("Error fetching arrival timings");
      throw Exception('Failed to load data');
    }
  }

  // function to properly sort the bus arrival info according to the Bus Service number and to filter it based on users favourite services
  List<ServiceInfo> filterBusArrivalInfo(BusArrivalInfo value) {
    var _value = value;
    var filteredList =
        _value.services.where((value) => widget.services.contains(value.serviceNum)).toList();
    filteredList.sort((a, b) => compareNatural(a.serviceNum, b.serviceNum));

    return filteredList;
  }

  // function to fetch bus arrival info and update the state of the widget, and to set a timer to fetch bus arrival info again after 30 seconds
  @override
  void initState() {
    super.initState();
    futureBusArrivalInfo = fetchArrivalTimings().then((value) => filterBusArrivalInfo(value));
    timer = Timer.periodic(
      const Duration(seconds: 30),
      (Timer t) => setState(() {
        futureBusArrivalInfo = fetchArrivalTimings().then((value) => filterBusArrivalInfo(value));
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = context.watch<User?>();

    return StreamBuilder(
        stream: SettingsService().streamSettings(user?.uid),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            UserSettings userSettings = snapshot.data as UserSettings;
            return Tooltip(
              preferBelow: false,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
              ),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              showDuration: const Duration(milliseconds: 350),
              message: widget.name,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => BusTimingScreen(
                            code: widget.code,
                            name: widget.name,
                            address: widget.address,
                            busStopLocation: widget.busStopLocation,
                          ),
                      settings: const RouteSettings(name: "BusTimingScreen")),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 18, bottom: 4),
                        child: Text(
                          widget.name,
                          overflow: TextOverflow.fade,
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: AppColors.kindaGrey),
                        ),
                      ),
                      FutureBuilder(
                          future: futureBusArrivalInfo,
                          builder: (context, AsyncSnapshot<List<ServiceInfo>> snapshot) {
                            if (snapshot.hasData) {
                              return snapshot.data!.isNotEmpty
                                  ? ListView.separated(
                                      itemBuilder: (context, int index) {
                                        return Transform.scale(
                                          scale: 0.9,
                                          child: BusTimingRow(
                                            busStopCode: widget.code,
                                            serviceInfo: snapshot.data![index],
                                            userLatLng: widget.busStopLocation,
                                            isETAminutes: userSettings.isETAminutes,
                                          ),
                                        );
                                      },
                                      separatorBuilder: (BuildContext context, int index) =>
                                          const SizedBox(
                                        height: 6,
                                      ),
                                      physics: const NeverScrollableScrollPhysics(),
                                      padding: const EdgeInsets.only(bottom: 18),
                                      shrinkWrap: true,
                                      itemCount: snapshot.data!.length,
                                    )
                                  : Center(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          top: 16,
                                          bottom: 24,
                                          left: 16,
                                          right: 16,
                                        ),
                                        child: Text(
                                          Jiffy.now().hour > 5
                                              ? '🦥 Your favourites are lepaking 🦥'
                                              : "💤 Buses are sleeping 💤",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    );
                            } else if (snapshot.hasError) {
                              // return Text("${snapshot.error}");
                              debugPrint("<=== ERROR ${snapshot.error} ===>");
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: const ErrorText(),
                                ),
                              );
                            } else if (snapshot.connectionState == ConnectionState.waiting) {
                              return ListView.separated(
                                  itemBuilder: (context, index) => const SkeletonItem(
                                        child: SkeletonLine(
                                          style: SkeletonLineStyle(
                                              height: 55,
                                              borderRadius: BorderRadius.all(Radius.circular(10)),
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 1.5)),
                                        ),
                                      ),
                                  separatorBuilder: (BuildContext context, int index) =>
                                      const SizedBox(
                                        height: 12,
                                      ),
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.only(bottom: 18),
                                  shrinkWrap: true,
                                  itemCount: widget.services.length);
                            } else {
                              return const SizedBox(height: 10);
                            }
                          }),
                    ],
                  ),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            // return Text("${snapshot.error}");
            debugPrint("<=== ERROR ${snapshot.error} ===>");
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const ErrorText(),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
              ),
            );
          }
        });
  }

  // function to dispose the timer when the widget is disposed
  @override
  void dispose() {
    timer.cancel();
    debugPrint("Timer cancelled");
    super.dispose();
  }
}
