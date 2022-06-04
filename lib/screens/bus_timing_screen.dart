import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:transito/models/arrival_info.dart';
import 'package:transito/widgets/bus_timing_row.dart';
import 'package:http/http.dart' as http;

import '../models/mock_data.dart';
import '../models/secret.dart';

class BusTimingScreen extends StatefulWidget {
  const BusTimingScreen({Key? key}) : super(key: key);
  static String routeName = '/BusTiming';

  @override
  State<BusTimingScreen> createState() => _BusTimingScreenState();
}

class _BusTimingScreenState extends State<BusTimingScreen> {
  final Distance distance = const Distance();
  final String busStopCode = '72069';
  Map<String, String> requestHeaders = {
    'Accept': 'application/json',
    'AccountKey': Secret.LtaApiKey
  };

  late Future<BusArrivalInfo> futureBusArrivalInfo;

  @override
  void initState() {
    super.initState();
    futureBusArrivalInfo = fetchArrivalTimings()
        //     .then((value) {
        //   var _value = value;
        //   _value.services.sort((a, b) => a.serviceNum.compareTo(b.serviceNum));
        //   return _value;
        // })
        ;
  }

  Future<Position> getUserLocation() async {
    debugPrint("Fetching user location");
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    debugPrint('$position');
    return position;
  }

  Future<BusArrivalInfo> fetchArrivalTimings() async {
    debugPrint("Fetching arrival timings");
    final response = await http.get(
        Uri.parse(
            'http://datamall2.mytransport.sg/ltaodataservice/BusArrivalv2?BusStopCode=$busStopCode'),
        headers: requestHeaders);

    if (response.statusCode == 200) {
      debugPrint("${BusArrivalInfo.fromJson(jsonDecode(response.body))}");
      return BusArrivalInfo.fromJson(jsonDecode(response.body));
    } else {
      debugPrint("Error fetching arrival timings");
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BusStopName'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: FutureBuilder(
          future: Future.wait([
            getUserLocation(),
            futureBusArrivalInfo,
          ]),
          builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.hasData) {
              return ListView.separated(
                  itemBuilder: (BuildContext context, int index) {
                    return BusTimingRow(
                      serviceInfo: snapshot.data![1].services[index],
                      userLatLng: LatLng(snapshot.data![0].latitude, snapshot.data![0].longitude),
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) => const Divider(),
                  itemCount: snapshot.data![1].services.length);
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() {
          futureBusArrivalInfo = fetchArrivalTimings();
        }),
        child: const Icon(Icons.refresh_rounded, size: 28),
      ),
    );
  }
}
