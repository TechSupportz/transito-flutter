import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/bus_stops.dart';
import '../../widgets/bus_stop_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

late Future<List<BusStopInfo>> busStops;

class _HomeScreenState extends State<HomeScreen> {
  // Future<Position> getUserLocation() async {
  //   debugPrint("Fetching user location");
  //   Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  //   debugPrint('$position');
  //   return position;
  // }

  Future<List<BusStopInfo>> fetchBusStops() async {
    debugPrint("Fetching bus stops");
    final String response = await rootBundle.loadString('assets/mock_data.json');
    return AllBusStops.fromJson(jsonDecode(response)).busStops;
  }

  @override
  void initState() {
    super.initState();
    busStops = fetchBusStops();
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
              future: busStops,
              builder: (BuildContext context, AsyncSnapshot<List<BusStopInfo>> snapshot) {
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
                        BusStopCard(
                          busStopInfo: snapshot.data![0],
                        ),
                        BusStopCard(
                          busStopInfo: snapshot.data![1],
                        ),
                        BusStopCard(
                          busStopInfo: snapshot.data![28],
                        ),
                        BusStopCard(
                          busStopInfo: snapshot.data![173],
                        ),
                        BusStopCard(
                          busStopInfo: snapshot.data![1933],
                        ),
                        BusStopCard(
                          busStopInfo: snapshot.data![500],
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
