import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_skeleton_ui/flutter_skeleton_ui.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/common_provider.dart';
import 'package:transito/global/services/favourites_service.dart';
import 'package:transito/models/api/lta/arrival_info.dart';
import 'package:transito/models/api/transito/bus_services.dart';
import 'package:transito/models/secret.dart';
import 'package:transito/screens/favourites/add_favourite_screen.dart';
import 'package:transito/screens/favourites/edit_favourite_screen.dart';
import 'package:transito/widgets/bus_info/bus_service_chip.dart';
import 'package:transito/widgets/common/error_text.dart';
import 'package:url_launcher/url_launcher.dart';

import 'bus_timing_screen.dart';

class BusStopInfoScreen extends StatefulWidget {
  const BusStopInfoScreen({
    super.key,
    required this.code,
    required this.name,
    required this.address,
    required this.busStopLocation,
    this.services,
  });

  final String code;
  final String name;
  final String address;
  final LatLng busStopLocation;
  final List<String>? services;

  @override
  State<BusStopInfoScreen> createState() => _BusStopInfoScreenState();
}

class _BusStopInfoScreenState extends State<BusStopInfoScreen> {
  late Future<List<String>> futureCurrOperatingServices;
  late Future<List<String>> futureServices;
  bool isAddedToFavourites = false;

  // api request headers
  Map<String, String> requestHeaders = {
    'Accept': 'application/json',
    'AccountKey': Secret.LTA_API_KEY
  };

  // function to fetch all services of a bus stop
  Future<List<String>> fetchServices() async {
    if (widget.services != null) {
      debugPrint("Retrieving services from props");
      return widget.services!;
    }

    debugPrint("Fetching all services");

    final response = await http.get(
      Uri.parse('${Secret.API_URL}/bus-stop/${widget.code}/services'),
    );

    if (response.statusCode == 200) {
      debugPrint("Services fetched");
      return BusStopServicesApiResponse.fromJson(json.decode(response.body)).data;
    } else {
      debugPrint("Error fetching bus stop services");
      throw Exception("Error fetching bus stop services");
    }
  }

  // function to fetch currently operating services bus arrival info
  Future<List<String>> fetchCurrOperatingServices() async {
    debugPrint("Fetching currently operating services");
    // gets response from api
    final response = await http.get(
        Uri.parse(
            'https://datamall2.mytransport.sg/ltaodataservice/v3/BusArrival?BusStopCode=${widget.code}'),
        headers: requestHeaders);

    // if response is successful, parse the response and return it as a BusArrivalInfo object
    if (response.statusCode == 200) {
      debugPrint("Currently operating services fetched");
      final busArrivalInfo = BusArrivalInfo.fromJson(jsonDecode(response.body));
      return busArrivalInfo.services.map((e) => e.serviceNum).toList();
    } else {
      debugPrint("Error fetching currently operating services");
      throw Exception('Failed to load data');
    }
  }

  Future<void> openMaps(LatLng navigationLocation) async {
    Uri uri = Uri.parse(
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
          code: widget.code,
          name: widget.name,
          address: widget.address,
          busStopLocation: widget.busStopLocation,
        ),
        settings: const RouteSettings(name: 'BusTimingScreen'),
      ),
    );
  }

  // function to get the list of bus services that are currently operating at that bus stop and route to the add favourites screen
  Future<void> goToAddFavouritesScreen() async {
    List<String> busServicesList = await futureServices;
    // debugPrint('$busServicesList');
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFavouritesScreen(
          busStopCode: widget.code,
          busStopName: widget.name,
          busStopAddress: widget.address,
          busStopLocation: widget.busStopLocation,
          busServicesList: busServicesList,
        ),
        settings: const RouteSettings(name: 'AddFavouritesScreen'),
      ),
    );
  }

  // function to get the list of bus services that are currently operating at that bus stop and route to the edit favourites screen
  Future<void> goToEditFavouritesScreen() async {
    List<String> busServicesList = await futureServices;
    // debugPrint('$busServicesList');
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditFavouritesScreen(
          busStopCode: widget.code,
          busStopName: widget.name,
          busStopAddress: widget.address,
          busStopLocation: widget.busStopLocation,
          busServicesList: busServicesList,
        ),
        settings: const RouteSettings(name: 'EditFavouritesScreen'),
      ),
    );
  }

  // initialise futureBusArrivalInfo and futureBusServices onInit
  @override
  void initState() {
    super.initState();
    futureCurrOperatingServices = fetchCurrOperatingServices();
    futureServices = fetchServices();

    var userId = context.read<User?>()?.uid;
    FavouritesService().isAddedToFavourites(widget.code, userId!).then((value) {
      setState(() {
        isAddedToFavourites = value;
        debugPrint('isAddedToFavourites: $isAddedToFavourites');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = context.read<CommonProvider>().isTablet;

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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 160, left: 12, right: 12, top: 16),
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
                          widget.name,
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                widget.code,
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onPrimary),
                              ),
                            ),
                            Text(
                              widget.address,
                              overflow: TextOverflow.fade,
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic),
                            )
                          ],
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bus Services',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        FutureBuilder(
                            future: Future.wait([futureCurrOperatingServices, futureServices]),
                            builder:
                                (BuildContext context, AsyncSnapshot<List<List<String>>> snapshot) {
                              if (snapshot.hasData) {
                                final currOperatingServices = snapshot.data![0];
                                final services = snapshot.data![1];

                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                      services //TODO - This list should contain the origin and destination of the bus service. (Minimally the origin)
                                          .map(
                                            (service) => BusServiceChip(
                                              busServiceNumber: service,
                                              currentStopCode: widget.code,
                                              isOperating: currOperatingServices.contains(service),
                                            ),
                                          )
                                          .toList(),
                                );
                              } else if (snapshot.hasError) {
                                // return Text("${snapshot.error}");
                                debugPrint("<=== ERROR ${snapshot.error} ===>");
                                return const ErrorText();
                              } else {
                                return Center(
                                  child: SkeletonLine(
                                    style: SkeletonLineStyle(
                                      height: 50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              }
                            }),
                      ],
                    ),
                    const SizedBox(
                      height: 16,
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
                          height: isTablet ? 800 : 400,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: widget.busStopLocation,
                                minZoom: 11,
                                initialZoom: 17.5,
                                maxZoom: 18,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.all &
                                      ~InteractiveFlag.pinchMove &
                                      ~InteractiveFlag.rotate,
                                ),
                                backgroundColor: const Color(0xFF003653),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      "https://www.onemap.gov.sg/maps/tiles/Night_HD/{z}/{x}/{y}.png",
                                  fallbackUrl:
                                      "https://www.onemap.gov.sg/maps/tiles/Night/{z}/{x}/{y}.png",
                                  userAgentPackageName: 'com.tnitish.transito',
                                  errorImage: const AssetImage('assets/images/mapError.png'),
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: widget.busStopLocation,
                                      child: Icon(
                                        Icons.place_rounded,
                                        size: 35,
                                        color: Theme.of(context).colorScheme.primary,
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
              padding: const EdgeInsets.only(bottom: 16, top: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Colors.transparent,
                  ],
                  stops: [0.9, 1.0],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed: () => goToBusTimingScreen(),
                    child: const Text('View Bus Timings'),
                  ),
                  OutlinedButton(
                    onPressed: () => openMaps(widget.busStopLocation),
                    child: const Text("Take me there!"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
