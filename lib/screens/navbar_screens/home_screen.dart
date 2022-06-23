import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:transito/models/app_colors.dart';
import 'package:transito/models/favourite.dart';
import 'package:transito/models/nearby_bus_stops.dart';
import 'package:transito/providers/favourites_provider.dart';
import 'package:transito/screens/mrt_map_screen.dart';
import 'package:transito/screens/onboarding_screens/location_access_screen.dart';

import '../../models/bus_stops.dart';
import '../../widgets/bus_stop_card.dart';
import '../../widgets/favourites_timing_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

List<NearbyBusStops> _nearbyBusStopsCache = [];
const distance = Distance();

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<NearbyBusStops>> nearbyBusStops;
  late Future<bool> _isLocationPermissionGranted;
  bool isFabVisible = true;

  bool hideFabOnScroll(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.forward) {
      !isFabVisible ? setState(() => isFabVisible = true) : null;
    } else if (notification.direction == ScrollDirection.reverse) {
      isFabVisible ? setState(() => isFabVisible = false) : null;
    }

    return true;
  }

  Future<bool> checkLocationPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever ||
        permission == LocationPermission.unableToDetermine) {
      return false;
    } else {
      return true;
    }
  }

  Future<Position> getUserLocation() async {
    debugPrint("Fetching user location");
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    debugPrint('$position');
    return position;
  }

  Future<List<BusStopInfo>> fetchBusStops() async {
    debugPrint("Fetching bus stops");
    final String response = await rootBundle.loadString('assets/bus_stops.json');
    return AllBusStops.fromJson(jsonDecode(response)).busStops;
  }

  Future<List<NearbyBusStops>> getNearbyBusStops({bool refresh = false}) async {
    if (_nearbyBusStopsCache.isNotEmpty && !refresh) {
      debugPrint("Nearby bus stops already fetched");
      return _nearbyBusStopsCache;
    } else {
      debugPrint("Fetching nearby bus stops");
      List<NearbyBusStops> _nearbyBusStops = [];
      Position userLocation = await getUserLocation();
      List<BusStopInfo> allBusStops = await fetchBusStops();

      for (var busStop in allBusStops) {
        LatLng busStopLocation = LatLng(busStop.latitude, busStop.longitude);
        double distanceAway = distance.as(LengthUnit.Meter,
            LatLng(userLocation.latitude, userLocation.longitude), busStopLocation);
        if (distanceAway <= 500) {
          _nearbyBusStops.add(NearbyBusStops(busStopInfo: busStop, distanceFromUser: distanceAway));
        }
      }
      List<NearbyBusStops> _tempNearbyBusStops = _nearbyBusStops;
      _tempNearbyBusStops.sort((a, b) => a.distanceFromUser.compareTo(b.distanceFromUser));
      _nearbyBusStopsCache = _tempNearbyBusStops;
      return _tempNearbyBusStops;
    }
  }

  void refreshBusStops() {
    setState(() {
      nearbyBusStops = getNearbyBusStops(refresh: true);
    });
  }

  @override
  void initState() {
    super.initState();
    debugPrint("Initializing bus stops");
    _isLocationPermissionGranted = checkLocationPermissions();
    nearbyBusStops = getNearbyBusStops();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MrtMapScreen(),
              ),
            ),
            icon: Icon(Icons.map_rounded),
          )
        ],
      ),
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) => hideFabOnScroll(notification),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 32),
          child: FutureBuilder(
              future: _isLocationPermissionGranted,
              builder: (context, AsyncSnapshot<bool> snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data!) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NearbyFavouritesGrid(userLocation: getUserLocation()),
                        nearbyBusStopsGrid(),
                      ],
                    );
                  } else {
                    return Material(
                      color: AppColors.cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          children: [
                            const Text(
                              "Please grant location permission to use this feature",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            TextButton(
                                onPressed: () => Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LocationAccessScreen(),
                                    ),
                                    (route) => false),
                                child: const Text("Grant permission")),
                          ],
                        ),
                      ),
                    );
                  }
                } else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              }),
        ),
      ),
      floatingActionButton: isFabVisible
          ? FloatingActionButton(
              onPressed: () {
                refreshBusStops();
                HapticFeedback.lightImpact();
              },
              child: const Icon(Icons.my_location_rounded),
            )
          : null,
    );
  }

  Column nearbyBusStopsGrid() {
    return Column(
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
                return GridView.count(
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
    );
  }
}

class NearbyFavouritesGrid extends StatefulWidget {
  const NearbyFavouritesGrid({Key? key, required this.userLocation}) : super(key: key);
  final Future<Position> userLocation;

  @override
  State<NearbyFavouritesGrid> createState() => _NearbyFavouritesGridState();
}

class _NearbyFavouritesGridState extends State<NearbyFavouritesGrid> {
  List<NearbyFavourites> _nearbyFavouritesCache = [];

  Future<List<NearbyFavourites>> getNearbyFavourites(
      {bool refresh = false, required List<Favourite> favouritesList}) async {
    // if (_nearbyFavouritesCache.isNotEmpty && !refresh) {
    //   debugPrint("Nearby Favourites already fetched");
    //   return _nearbyFavouritesCache;
    // } else {
    debugPrint("Fetching nearby favourites");
    List<NearbyFavourites> _nearbyFavourites = [];
    Position userLocation = await widget.userLocation;

    for (var busStop in favouritesList) {
      LatLng busStopLocation = LatLng(busStop.latitude, busStop.longitude);
      double distanceAway = distance.as(
          LengthUnit.Meter, LatLng(userLocation.latitude, userLocation.longitude), busStopLocation);
      if (distanceAway <= 750) {
        _nearbyFavourites
            .add(NearbyFavourites(busStopInfo: busStop, distanceFromUser: distanceAway));
      }
    }
    List<NearbyFavourites> _tempNearbyFavourites = _nearbyFavourites;
    _tempNearbyFavourites.sort((a, b) => a.distanceFromUser.compareTo(b.distanceFromUser));
    _nearbyFavouritesCache = _tempNearbyFavourites;
    return _tempNearbyFavourites;
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavouritesProvider>(builder: (context, value, child) {
      return value.favouritesList.isNotEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Nearby Favourites",
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 12,
                ),
                FutureBuilder(
                    future: getNearbyFavourites(favouritesList: value.favouritesList),
                    builder:
                        (BuildContext context, AsyncSnapshot<List<NearbyFavourites>> snapshot) {
                      if (snapshot.hasData) {
                        if (snapshot.data!.isNotEmpty) {
                          return ListView.separated(
                            itemBuilder: (context, int index) {
                              return FavouritesTimingCard(
                                busStopCode: snapshot.data![index].busStopInfo.busStopCode,
                                busStopName: snapshot.data![index].busStopInfo.busStopName,
                                busStopAddress: snapshot.data![index].busStopInfo.busStopAddress,
                                busStopLocation: LatLng(snapshot.data![index].busStopInfo.latitude,
                                    snapshot.data![index].busStopInfo.longitude),
                                services: snapshot.data![index].busStopInfo.services,
                              );
                            },
                            separatorBuilder: (BuildContext context, int index) => const SizedBox(
                              height: 18,
                            ),
                            padding: const EdgeInsets.only(bottom: 18.0),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data!.length,
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 18.0),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text("No favourites nearby",
                                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18)),
                              ),
                            ),
                          );
                        }
                      } else if (snapshot.hasError) {
                        return Text("${snapshot.error}");
                      } else {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    })
              ],
            )
          : const SizedBox();
    });
  }
}
