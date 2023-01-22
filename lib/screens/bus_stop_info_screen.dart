import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'package:http/http.dart' as http;
import 'package:jiffy/jiffy.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:transito/models/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/arrival_info.dart';
import '../models/secret.dart';
import '../providers/favourites_service.dart';
import '../widgets/bus_service_box.dart';
import '../widgets/error_text.dart';
import 'add_favourite_screen.dart';
import 'bus_timing_screen.dart';
import 'edit_favourite_screen.dart';

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
  bool isAddedToFavourites = false;

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
    // debugPrint('${busServicesList.isEmpty}');
    return busServicesList;
  }

  Future<void> openMaps(LatLng navigationLocation) async {
    var uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${navigationLocation.latitude},${navigationLocation.longitude}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch Google Maps';
    }
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

  // function to get the list of bus services that are currently operating at that bus stop and route to the add favourites screen
  Future<void> goToAddFavouritesScreen() async {
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

  // function to get the list of bus services that are currently operating at that bus stop and route to the edit favourites screen
  Future<void> goToEditFavouritesScreen() async {
    List<String> busServicesList = await getBusServiceNumList();
    // debugPrint('$busServicesList');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditFavouritesScreen(
          busStopCode: widget.busStopCode,
          busStopName: widget.busStopName,
          busStopAddress: widget.busStopAddress,
          busStopLocation: widget.busStopLocation,
          busServicesList: busServicesList,
        ),
      ),
    );
  }

  // initialise futureBusArrivalInfo and futureBusServices onInit
  @override
  void initState() {
    super.initState();
    futureBusArrivalInfo = fetchArrivalTimings();
    futureBusServices = getBusServiceNumList();

    var userId = context.read<User?>()?.uid;
    FavouritesService().isAddedToFavourites(widget.busStopCode, userId!).then((value) {
      setState(() {
        isAddedToFavourites = value;
        debugPrint('isAddedToFavourites: $isAddedToFavourites');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Stop Information'),
        actions: [
          isAddedToFavourites
              ? IconButton(
                  icon: const Icon(Icons.favorite_rounded),
                  onPressed: () => goToEditFavouritesScreen(),
                )
              : IconButton(
                  icon: const Icon(Icons.favorite_border_rounded),
                  onPressed: () => goToAddFavouritesScreen(),
                ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 128),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    color: AppColors.accentColour,
                                    borderRadius: BorderRadius.circular(5)),
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
                              builder:
                                  (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
                                if (snapshot.hasData) {
                                  return snapshot.data!.isEmpty
                                      ? Text(
                                          Jiffy().hour > 5
                                              ? 'All the buses are lepaking 🦥'
                                              : "Buses are sleeping 💤",
                                          style: const TextStyle(
                                            fontSize: 18,
                                          ),
                                        )
                                      : Wrap(
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
                                  // return Text("${snapshot.error}");
                                  debugPrint("<=== ERROR ${snapshot.error} ===>");
                                  return const ErrorText();
                                } else {
                                  return const Center(child: CircularProgressIndicator());
                                }
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
                          SizedBox(
                            width: double.infinity,
                            height: 400,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: FlutterMap(
                                options: MapOptions(
                                  center: widget.busStopLocation,
                                  minZoom: 11,
                                  zoom: 17,
                                  maxZoom: 18,
                                  interactiveFlags: InteractiveFlag.all &
                                      ~InteractiveFlag.pinchMove &
                                      ~InteractiveFlag.rotate,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        "https://maps-a.onemap.sg/v3/Night/{z}/{x}/{y}.png",
                                    userAgentPackageName: 'tnitish.com.transito',
                                    errorImage: const AssetImage('assets/images/mapError.png'),
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: widget.busStopLocation,
                                        builder: (context) => Icon(
                                          Icons.place_rounded,
                                          size: 35,
                                          color: AppColors.accentColour,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.only(bottom: 16, top: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xFF0c0c0c),
                      Colors.transparent,
                    ],
                    stops: [0.9, 1.0],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () => openMaps(widget.busStopLocation),
                      child: const Text("Take me there!"),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    ElevatedButton(
                      onPressed: () => goToBusTimingScreen(),
                      child: const Text('View Bus Timings'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
