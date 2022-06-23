import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:transito/widgets/bus_timing_row.dart';

import '../models/app_colors.dart';
import '../models/arrival_info.dart';
import '../models/secret.dart';
import '../screens/bus_timing_screen.dart';

class FavouritesTimingCard extends StatefulWidget {
  const FavouritesTimingCard({
    Key? key,
    required this.busStopCode,
    required this.busStopName,
    required this.busStopAddress,
    required this.busStopLocation,
    required this.services,
  }) : super(key: key);

  final String busStopCode;
  final String busStopName;
  final String busStopAddress;
  final LatLng busStopLocation;
  final List<String?> services;

  @override
  State<FavouritesTimingCard> createState() => _FavouritesTimingCardState();
}

class _FavouritesTimingCardState extends State<FavouritesTimingCard> {
  late Future<List<ServiceInfo>> futureBusArrivalInfo;
  late Timer timer;

  Map<String, String> requestHeaders = {
    'Accept': 'application/json',
    'AccountKey': Secret.LtaApiKey
  };

  Future<BusArrivalInfo> fetchArrivalTimings() async {
    debugPrint("Fetching arrival timings");
    final response = await http.get(
        Uri.parse(
            'http://datamall2.mytransport.sg/ltaodataservice/BusArrivalv2?BusStopCode=${widget.busStopCode}'),
        headers: requestHeaders);

    if (response.statusCode == 200) {
      debugPrint("Timing fetched");
      return BusArrivalInfo.fromJson(jsonDecode(response.body));
    } else {
      debugPrint("Error fetching arrival timings");
      throw Exception('Failed to load data');
    }
  }

  List<ServiceInfo> filterBusArrivalInfo(BusArrivalInfo value) {
    var _value = value;
    var _filteredList =
        _value.services.where((value) => widget.services.contains(value.serviceNum)).toList();
    _filteredList.sort((a, b) => compareNatural(a.serviceNum, b.serviceNum));

    return _filteredList;
  }

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
    return FutureBuilder(
        future: futureBusArrivalInfo,
        builder: (context, AsyncSnapshot<List<ServiceInfo>> snapshot) {
          if (snapshot.hasData) {
            return InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BusTimingScreen(
                    busStopCode: widget.busStopCode,
                    busStopName: widget.busStopName,
                    busStopAddress: widget.busStopAddress,
                    busStopLocation: widget.busStopLocation,
                  ),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 2),
                      child: Text(
                        widget.busStopName,
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.kindaGrey),
                      ),
                    ),
                    ListView.separated(
                        itemBuilder: (context, int index) {
                          return Transform.scale(
                            scale: 0.9,
                            child: BusTimingRow(
                              serviceInfo: snapshot.data![index],
                              userLatLng: widget.busStopLocation,
                            ),
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) => const SizedBox(
                              height: 6,
                            ),
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.only(bottom: 18),
                        shrinkWrap: true,
                        itemCount: snapshot.data!.length),
                  ],
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          } else {
            return const SizedBox(
              height: 0,
            );
          }
        });
  }

  @override
  void dispose() {
    timer.cancel();
    debugPrint("Timer cancelled");
    super.dispose();
  }
}
