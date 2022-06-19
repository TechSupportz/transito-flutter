import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:transito/models/arrival_info.dart';
import 'package:transito/widgets/bus_timing_row.dart';
import 'package:http/http.dart' as http;
import '../models/secret.dart';
import '../providers/favourites_provider.dart';
import 'add_favourite_screen.dart';

class BusTimingScreen extends StatefulWidget {
  const BusTimingScreen(
      {Key? key,
      required this.busStopCode,
      this.busStopName = 'Ayo?',
      required this.busStopAddress,
      required this.busStopLocation})
      : super(key: key);
  static String routeName = '/BusTiming';
  final String busStopCode;
  final String busStopName;
  final String busStopAddress;
  final LatLng busStopLocation;

  @override
  State<BusTimingScreen> createState() => _BusTimingScreenState();
}

class _BusTimingScreenState extends State<BusTimingScreen> {
  late Future<BusArrivalInfo> futureBusArrivalInfo;
  bool isFabVisible = true;
  late Timer timer;

  Future<Position> getUserLocation() async {
    debugPrint("Fetching user location");
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    debugPrint('$position');
    return position;
  }

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

  BusArrivalInfo sortBusArrivalInfo(BusArrivalInfo value) {
    var _value = value;
    _value.services.sort((a, b) => compareNatural(a.serviceNum, b.serviceNum));

    return _value;
  }

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

  Future<void> goToAddFavouritesScreen(BuildContext context) async {
    List<String> busServicesList = await getBusServiceNumList();
    // debugPrint('$busServicesList');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFavouritesScreen(
          busStopCode: widget.busStopCode,
          busStopName: widget.busStopName,
          busStopAddress: widget.busStopAddress,
          busStopLocation: widget.busStopLocation,
          busServicesList: busServicesList,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    futureBusArrivalInfo = fetchArrivalTimings().then((value) => sortBusArrivalInfo(value));
    timer = Timer.periodic(
        const Duration(seconds: 30),
        (Timer t) => setState(() {
              futureBusArrivalInfo =
                  fetchArrivalTimings().then((value) => sortBusArrivalInfo(value));
              ;
            }));
  }

  @override
  void dispose() {
    timer.cancel();
    debugPrint("Timer cancelled");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavouritesProvider>(
      builder: (context, value, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.busStopName),
            actions: [
              value.favouritesList.every((element) => element.busStopCode != widget.busStopCode)
                  ? IconButton(
                      icon: const Icon(Icons.favorite_border_rounded),
                      onPressed: () => goToAddFavouritesScreen(context),
                    )
                  : IconButton(
                      icon: const Icon(Icons.favorite_rounded),
                      onPressed: () =>
                          print('already added to favourites'), //TODO: replace with snackbar
                    )
            ],
          ),
          body: FutureBuilder(
            future: futureBusArrivalInfo,
            builder: (BuildContext context, AsyncSnapshot<BusArrivalInfo> snapshot) {
              if (snapshot.hasData) {
                return NotificationListener<UserScrollNotification>(
                  onNotification: (notification) {
                    if (notification.direction == ScrollDirection.forward) {
                      !isFabVisible ? setState(() => isFabVisible = true) : null;
                    } else if (notification.direction == ScrollDirection.reverse) {
                      isFabVisible ? setState(() => isFabVisible = false) : null;
                    }

                    return true;
                  },
                  child: ListView.separated(
                      itemBuilder: (context, int index) {
                        return BusTimingRow(
                          serviceInfo: snapshot.data!.services[index],
                          userLatLng: widget.busStopLocation,
                        );
                      },
                      padding: const EdgeInsets.only(bottom: 32, left: 12, right: 12),
                      separatorBuilder: (BuildContext context, int index) => const Divider(),
                      itemCount: snapshot.data!.services.length),
                );
              } else if (snapshot.hasError) {
                return Text("${snapshot.error}");
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
          floatingActionButton: isFabVisible
              ? FloatingActionButton(
                  onPressed: () => setState(() {
                    futureBusArrivalInfo = fetchArrivalTimings().then(
                      (value) => sortBusArrivalInfo(value),
                    );
                    HapticFeedback.lightImpact();
                  }),
                  child: const Icon(Icons.refresh_rounded, size: 28),
                  enableFeedback: true,
                )
              : null,
        );
      },
    );
  }
}
