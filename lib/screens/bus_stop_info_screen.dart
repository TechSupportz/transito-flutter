import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:transito/models/app_colors.dart';

import '../models/arrival_info.dart';
import '../models/secret.dart';
import '../widgets/bus_service_box.dart';
import 'bus_timing_screen.dart';

class BusStopInfoScreen extends StatefulWidget {
  const BusStopInfoScreen(
      {Key? key,
      required this.busStopCode,
      required this.busStopName,
      required this.busStopAddress,
      required this.busStopLocation})
      : super(key: key);

  final String busStopCode;
  final String busStopName;
  final String busStopAddress;
  final LatLng busStopLocation;

  @override
  State<BusStopInfoScreen> createState() => _BusStopInfoScreenState();
}

class _BusStopInfoScreenState extends State<BusStopInfoScreen> {
  late Future<BusArrivalInfo> futureBusArrivalInfo;
  late Future<List<String>> futureBusServices;

  // api request headers
  Map<String, String> requestHeaders = {
    'Accept': 'application/json',
    'AccountKey': Secret.LtaApiKey
  };

  // function to fetch bus arrival info
  Future<BusArrivalInfo> fetchArrivalTimings() async {
    debugPrint("Fetching arrival timings");
    // gets response from api
    final response = await http.get(
        Uri.parse(
            'http://datamall2.mytransport.sg/ltaodataservice/BusArrivalv2?BusStopCode=${widget.busStopCode}'),
        headers: requestHeaders);

    // if response is successful, parse the response and return it as a BusArrivalInfo object
    if (response.statusCode == 200) {
      debugPrint("Timing fetched");
      return BusArrivalInfo.fromJson(jsonDecode(response.body));
    } else {
      debugPrint("Error fetching arrival timings");
      throw Exception('Failed to load data');
    }
  }

  // function to get the list of bus services that are currently operating at that bus stop
  Future<List<String>> getBusServiceNumList() async {
    List<String> busServicesList = await futureBusArrivalInfo.then(
      (value) {
        List<String> _busServicesList = [];
        for (var service in value.services) {
          _busServicesList.add(service.serviceNum);
          // debugPrint('$_busServicesList');
        }
        return _busServicesList;
      },
    );
    // debugPrint('$busServicesList');
    return busServicesList;
  }

  // a function that send the user to the bus timing screen
  void goToBusTimingScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusTimingScreen(
          busStopCode: widget.busStopCode,
          busStopName: widget.busStopName,
          busStopAddress: widget.busStopAddress,
          busStopLocation: widget.busStopLocation,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    futureBusArrivalInfo = fetchArrivalTimings();
    futureBusServices = getBusServiceNumList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Stop Information'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.busStopName,
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                              color: AppColors.veryPurple, borderRadius: BorderRadius.circular(5)),
                          child: Text(widget.busStopCode,
                              style: const TextStyle(fontWeight: FontWeight.w500)),
                        ),
                        Text(
                          widget.busStopAddress,
                          overflow: TextOverflow.fade,
                          maxLines: 1,
                          softWrap: false,
                          style: const TextStyle(
                              color: AppColors.kindaGrey, fontStyle: FontStyle.italic),
                        )
                      ],
                    )
                  ],
                ),
                const SizedBox(
                  height: 21,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Operating Bus Services',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    FutureBuilder(
                        future: futureBusServices,
                        builder: (context, AsyncSnapshot<List<String>> snapshot) {
                          if (snapshot.hasData) {
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: snapshot.data!
                                  .map(
                                    (serviceNum) => BusServiceBox(
                                      busServiceNumber: serviceNum,
                                    ),
                                  )
                                  .toList(),
                            );
                          } else if (snapshot.hasError) {
                            return Text("${snapshot.error}");
                          }
                          return const Center(child: CircularProgressIndicator());
                        }),
                  ],
                ),
                const SizedBox(
                  height: 21,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Image.asset('assets/images/placeholder-map.jpg'),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16, top: 21),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 42),
                    // button to trigger the request for the user's location permission
                    child: ElevatedButton(
                      onPressed: () => goToBusTimingScreen(),
                      child: const Text('View Bus Timings'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
