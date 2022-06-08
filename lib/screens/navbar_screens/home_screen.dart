import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:transito/models/nearby_bus_stops.dart';

import '../../models/bus_stops.dart';
import '../../widgets/bus_stop_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

late Future<List<NearbyBusStops>> nearbyBusStops;

class _HomeScreenState extends State<HomeScreen> {
  final distance = const Distance();

  Future<Position> getUserLocation() async {
    debugPrint("Fetching user location");
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    debugPrint('$position');
    return position;
  }

  Future<List<NearbyBusStops>> getNearbyBusStops({refresh = false}) async {
    debugPrint("Fetching nearby bus stops");
    // TODO: implement caching of nearby bus stops
    // if (refresh == true) {
    //   debugPrint("Nearby bus stops already fetched");
    //   return nearbyBusStops;
    // } else {
    List<NearbyBusStops> _nearbyBusStops = [];
    Position userLocation = await getUserLocation();
    List<BusStopInfo> allBusStops = await fetchBusStops();

    for (var busStop in allBusStops) {
      LatLng busStopLocation = LatLng(busStop.latitude, busStop.longitude);
      double distanceAway = distance.as(
          LengthUnit.Meter, LatLng(userLocation.latitude, userLocation.longitude), busStopLocation);
      if (distanceAway <= 500) {
        _nearbyBusStops.add(NearbyBusStops(busStopInfo: busStop, distanceFromUser: distanceAway));
      }
    }
    // setState(() {
    //   nearbyBusStops = _nearbyBusStops;
    // });

    List<NearbyBusStops> _tempNearbyBusStops = _nearbyBusStops;
    _tempNearbyBusStops.sort((a, b) => a.distanceFromUser.compareTo(b.distanceFromUser));
    return _tempNearbyBusStops;
  }
  // }

  Future<List<BusStopInfo>> fetchBusStops() async {
    debugPrint("Fetching bus stops");
    final String response = await rootBundle.loadString('assets/mock_data.json');
    return AllBusStops.fromJson(jsonDecode(response)).busStops;
  }

  @override
  void initState() {
    super.initState();
    debugPrint("Initializing bus stops");
    nearbyBusStops = getNearbyBusStops();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Nearby",
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(
            height: 12,
          ),
          FutureBuilder(
              future: nearbyBusStops,
              builder: (BuildContext context, AsyncSnapshot<List<NearbyBusStops>> snapshot) {
                if (snapshot.hasData) {
                  return Expanded(
                    child: GridView.count(
                      childAspectRatio: 2.5 / 1,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 21,
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (var busStop in snapshot.data!)
                          BusStopCard(
                            busStopInfo: busStop.busStopInfo,
                          ),
                      ],
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              })
        ],
      ),
    );
  }
}
