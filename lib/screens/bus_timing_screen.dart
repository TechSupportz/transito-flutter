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
  final Distance distance = const Distance();

  Future<Position> getUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    debugPrint('$position');
    return position;
  }

  final BusTimingInfo = jsonDecode(mockTestingData.mockData);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${BusTimingInfo['BusStopCode']}'),
      ),
      body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: FutureBuilder(
            future: getUserLocation(),
            builder: (BuildContext context, AsyncSnapshot<Position> snapshot) {
              if (snapshot.hasData) {
                return ListView.separated(
                    itemBuilder: (BuildContext context, int index) {
                      return BusTimingRow(
                        arrivalInfo: BusTimingInfo['Services'][index],
                        userLatLng: LatLng(snapshot.data!.latitude, snapshot.data!.longitude),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) => const Divider(),
                    itemCount: BusTimingInfo['Services'].length);
              } else if (snapshot.hasError) {
                return Text("${snapshot.error}");
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          )),
    );
  }
}
