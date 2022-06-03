import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:transito/widgets/bus_timing_row.dart';

import '../modals/mock_data.dart';

class BusTimingScreen extends StatefulWidget {
  const BusTimingScreen({Key? key}) : super(key: key);
  static String routeName = '/BusTiming';

  @override
  State<BusTimingScreen> createState() => _BusTimingScreenState();
}

class _BusTimingScreenState extends State<BusTimingScreen> {
  final Distance distance = new Distance();

  Future<Position> getUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    print(position);
    return position;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bus stop name"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Wrap(children: [
          FutureBuilder(
            future: getUserLocation(),
            builder: (BuildContext context, AsyncSnapshot<Position> snapshot) {
              if (snapshot.hasData) {
                return BusTimingRow(
                  arrivalInfo: jsonDecode(mockTestingData.mockData),
                  userLatLng: LatLng(snapshot.data!.latitude, snapshot.data!.longitude),
                );
              } else if (snapshot.hasError) {
                return Text("${snapshot.error}");
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          )
        ]),
      ),
    );
  }
}
