import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_skeleton_ui/flutter_skeleton_ui.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/common_provider.dart';
import 'package:transito/global/services/favourites_service.dart';
import 'package:transito/global/services/location_service.dart';
import 'package:transito/global/services/settings_service.dart';
import 'package:transito/global/services/transito_api_service.dart';
import 'package:transito/models/api/transito/nearby_bus_stops.dart';
import 'package:transito/models/app/app_typography.dart';
import 'package:transito/models/favourites/favourite.dart';
import 'package:transito/models/user/user_settings.dart';
import 'package:transito/screens/main/settings_screen.dart';
import 'package:transito/screens/onboarding/location_access_screen.dart';
import 'package:transito/widgets/bus_info/bus_stop_card.dart';
import 'package:transito/widgets/common/app_symbol.dart';
import 'package:transito/widgets/common/error_text.dart';
import 'package:transito/widgets/favourites/favourites_timing_card.dart';

class NearbyScreenController extends ChangeNotifier {
  void refresh() => notifyListeners();
}

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key, this.controller, required this.isActive});
  final NearbyScreenController? controller;
  final ValueListenable<bool> isActive;

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

const distance = Distance();

class _NearbyScreenState extends State<NearbyScreen> with WidgetsBindingObserver {
  late Future<List<NearbyBusStop>> nearbyBusStops;
  late Future<List<NearbyFavourites>> nearbyFavourites;
  StreamSubscription<Position?>? userLocationStream;
  bool _isFabVisible = true;

  LatLng _prevUserLocation = LatLng(0, 0);

  // sets the state of the FAB to hide or show depending if the user is scrolling in order to prevent blocking content
  bool hideFabOnScroll(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.forward) {
      !_isFabVisible ? setState(() => _isFabVisible = true) : null;
    } else if (notification.direction == ScrollDirection.reverse) {
      _isFabVisible ? setState(() => _isFabVisible = false) : null;
    }

    return true;
  }

  Future<List<NearbyBusStop>> getNearbyBusStops({
    Position? currentLocation,
  }) async {
    debugPrint("Fetching nearby bus stops");
    final Position? userLocation = currentLocation ?? await LocationService().getCurrentPosition();
    if (userLocation == null) {
      return [];
    }

    final List<NearbyBusStop> stops = await TransitoApiService().getNearbyBusStops(
      LatLng(userLocation.latitude, userLocation.longitude),
    );
    debugPrint("Nearby bus stops fetched");
    return stops;
  }

  // function to get the user's nearby favourites
  Future<List<NearbyFavourites>> getNearbyFavourites({
    Position? currentLocation,
  }) async {
    debugPrint("Fetching nearby favourites");
    List<NearbyFavourites> nearbyFavourites = [];
    List<Favourite> favouritesList = await FavouritesService().getFavourites(
      context.read<User>().uid,
    );
    final Position? userLocation = currentLocation ?? await LocationService().getCurrentPosition();
    if (userLocation == null) {
      return [];
    }

    // searches through the list of favourites and returns those within 750m to the user's current location sorted by nearest to farthest
    for (var favourite in favouritesList) {
      double distanceAway = distance.as(
        LengthUnit.Meter,
        LatLng(userLocation.latitude, userLocation.longitude),
        favourite.busStopLocation,
      );
      if (distanceAway <= 750) {
        nearbyFavourites.add(
          NearbyFavourites(busStopInfo: favourite, distanceFromUser: distanceAway),
        );
      }
    }
    List<NearbyFavourites> tempNearbyFavourites = nearbyFavourites;
    tempNearbyFavourites.sort((a, b) => a.distanceFromUser.compareTo(b.distanceFromUser));
    // _nearbyFavouritesCache = _tempNearbyFavourites;
    return tempNearbyFavourites;
    // }
  }

  // function to get the list of all nearby bus stops
  void getAllNearby({bool userInitiated = false}) async {
    debugPrint("Getting all nearby");
    final Position? userLocation = await LocationService().getCurrentPosition(
      userInitiated: userInitiated,
    );
    if (userLocation == null) {
      return;
    }

    setState(() {
      nearbyBusStops = getNearbyBusStops(currentLocation: userLocation);
      nearbyFavourites = getNearbyFavourites(currentLocation: userLocation);
    });

    if (userInitiated) {
      streamUserLocation(userInitiated: true);
    }
  }

  void streamUserLocation({bool userInitiated = false}) async {
    final canUseLocation = await LocationService().canUseLocation(userInitiated: userInitiated);
    if (!canUseLocation) {
      return;
    }

    await userLocationStream?.cancel();
    userLocationStream = LocationService().positionStream.listen((Position? position) {
      if (position == null) {
        return;
      }

      if (_prevUserLocation.latitude == position.latitude &&
          _prevUserLocation.longitude == position.longitude) {
        return;
      }
      setState(() {
        nearbyBusStops = getNearbyBusStops(currentLocation: position);
        nearbyFavourites = getNearbyFavourites(currentLocation: position);
        _prevUserLocation = LatLng(position.latitude, position.longitude);
      });
    });
  }

  @override
  void initState() {
    super.initState();
    debugPrint("Initializing bus stops");
    nearbyBusStops = getNearbyBusStops();
    nearbyFavourites = getNearbyFavourites();
    streamUserLocation();

    WidgetsBinding.instance.addObserver(this);

    widget.controller?.addListener(_handleControllerRefresh);
  }

  void _handleControllerRefresh() {
    getAllNearby(userInitiated: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      getAllNearby();
    }
  }

  @override
  void dispose() {
    userLocationStream?.cancel();
    debugPrint("Cancelling user location stream");

    WidgetsBinding.instance.removeObserver(this);
    widget.controller?.removeListener(_handleControllerRefresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var user = context.watch<User?>();
    bool supportsLiquidGlass = context.watch<CommonProvider>().supportsLiquidGlass;

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome ${user?.displayName ?? ''}'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
                settings: const RouteSettings(name: 'SettingsScreen'),
              ),
            ),
            icon: const AppSymbol(
              Symbols.settings_rounded,
              fill: true,
            ),
          ),
        ],
      ),
      // notification listener to call the hideFabOnScroll function when the user scrolls
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) => hideFabOnScroll(notification),
        child: RefreshIndicator(
          onRefresh: () async {
            return Future.delayed(
              const Duration(seconds: 0),
              () {
                getAllNearby(userInitiated: true);
              },
            );
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 32, top: 12),
            child: ValueListenableBuilder<bool>(
              valueListenable: LocationService().automaticRequestsSuppressed,
              builder: (context, automaticRequestsSuppressed, child) {
                if (automaticRequestsSuppressed) {
                  return locationUnavailableMessage();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 16,
                  children: [
                    nearbyFavouritesList(),
                    nearbyBusStopsGrid(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      // floating action button to refresh user's location and nearbyBusStops
      floatingActionButton: _isFabVisible && !supportsLiquidGlass
          ? FloatingActionButton(
              heroTag: "homeFAB",
              onPressed: () {
                getAllNearby(userInitiated: true);
                HapticFeedback.selectionClick();
              },
              child: const AppSymbol(Symbols.refresh_rounded),
            )
          : null,
    );
  }

  Widget locationUnavailableMessage() {
    return FutureBuilder<bool>(
      future: LocationService().hasLocationPermission(),
      builder: (context, snapshot) {
        final bool hasLocationPermission = snapshot.data ?? true;

        return ErrorText(
          enableBackground: true,
          title: "No clue where you are",
          message:
              'Turn on location and nearby stops can show up here. Otherwise, search works too.',
          icon: Symbols.location_off_rounded,
          action: hasLocationPermission
              ? null
              : TextButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LocationAccessScreen(),
                      settings: const RouteSettings(name: 'LocationAccessScreen'),
                    ),
                    (route) => false,
                  ),
                  child: const Text('Grant permission'),
                ),
        );
      },
    );
  }

  Column nearbyFavouritesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Nearby Favourites",
          style: AppTypography.sectionHeading,
        ),
        const SizedBox(
          height: 12,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
          child: FutureBuilder(
            future: nearbyFavourites,
            builder: (BuildContext context, AsyncSnapshot<List<NearbyFavourites>> snapshot) {
              Widget favouritesListWidget = const SizedBox();

              if (snapshot.hasData && snapshot.connectionState == ConnectionState.done) {
                // checks if user has any favourites within 750m of their current location and displays them if they do
                if (snapshot.data!.isEmpty) {
                  favouritesListWidget = Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        "No favourites nearby",
                        style: AppTypography.cardSubtitle,
                      ),
                    ),
                  );
                } else {
                  favouritesListWidget = ListView.separated(
                    itemBuilder: (context, int index) {
                      return FavouritesTimingCard(
                        key: ValueKey(snapshot.data![index].busStopInfo.busStopCode),
                        isActive: widget.isActive,
                        code: snapshot.data![index].busStopInfo.busStopCode,
                        name: snapshot.data![index].busStopInfo.busStopName,
                        address: snapshot.data![index].busStopInfo.busStopAddress,
                        busStopLocation: snapshot.data![index].busStopInfo.busStopLocation,
                        services: snapshot.data![index].busStopInfo.services,
                        sources: snapshot.data![index].busStopInfo.sources,
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) => const SizedBox(
                      height: 16,
                    ),
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                  );
                }
              }

              if (snapshot.hasError) {
                // return Text("${snapshot.error}");
                debugPrint("<=== ERROR ${snapshot.error} ===>");
                favouritesListWidget = const ErrorText(
                  enableBackground: true,
                  icon: Symbols.heart_broken_rounded,
                  title: "Couldn't load favourites",
                );
              }

              return Skeleton(
                isLoading: snapshot.connectionState == ConnectionState.waiting,
                skeleton: SkeletonLine(
                  style: SkeletonLineStyle(height: 128, borderRadius: BorderRadius.circular(12)),
                ),
                child: favouritesListWidget,
              );
              // display a loading indicator while the list of nearby favourites is being fetched
            },
          ),
        ),
      ],
    );
  }

  Column nearbyBusStopsGrid() {
    bool isTablet = context.read<CommonProvider>().isTablet;
    bool supportsLiquidGlass = context.watch<CommonProvider>().supportsLiquidGlass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Nearby",
          style: AppTypography.sectionHeading,
        ),
        const SizedBox(
          height: 12,
        ),
        StreamBuilder(
          stream: SettingsService().streamSettings(context.watch<User?>()?.uid),
          builder: (context, userSettingsSnapshot) {
            if (userSettingsSnapshot.hasData) {
              UserSettings userSettings = userSettingsSnapshot.data as UserSettings;

              GridView renderGridView(List<Widget> children) {
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isTablet
                        ? (userSettings.isNearbyGrid ? 3 : 1)
                        : (userSettings.isNearbyGrid ? 2 : 1),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 80,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: children.length,
                  itemBuilder: (context, index) {
                    return children[index];
                  },
                );
              }

              return FutureBuilder(
                future: nearbyBusStops,
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<List<NearbyBusStop>> nearbyBusStopList,
                    ) {
                      Widget busStopsResultsWidget = const SizedBox();
                      // display a loading indicator while the list of nearby bus stops is being fetched
                      if (nearbyBusStopList.hasData && nearbyBusStopList.data != null) {
                        if (nearbyBusStopList.data!.isNotEmpty) {
                          busStopsResultsWidget = renderGridView(
                            [
                              // loop through nearby bus stops and send their data to the BusStopCard widget to display them
                              for (var data in nearbyBusStopList.data!)
                                BusStopCard(
                                  busStopInfo: data.busStop,
                                  distanceFromUser: data.distanceAway,
                                  showDistanceFromUser: userSettings.showNearbyDistance,
                                ),
                            ],
                          );
                        } else {
                          busStopsResultsWidget = const ErrorText(
                            enableBackground: true,
                            icon: Symbols.bus_map_pin_rounded,
                            title: "No bus stops nearby",
                            message: "Try moving to a less ulu place",
                          );
                        }
                      }

                      if (nearbyBusStopList.hasError) {
                        // return Text("${snapshot.error}");
                        debugPrint("<=== ERROR ${nearbyBusStopList.error} ===>");
                        busStopsResultsWidget = Padding(
                          padding: EdgeInsets.only(bottom: supportsLiquidGlass ? 80.0 : 0),
                          child: const ErrorText(
                            enableBackground: true,
                            title: "Couldn't load nearby stops",
                          ),
                        );
                      }

                      return Skeleton(
                        isLoading: nearbyBusStopList.connectionState == ConnectionState.waiting,
                        skeleton: renderGridView(
                          [
                            for (var i = 0; i < 16; i++)
                              SkeletonLine(
                                style: SkeletonLineStyle(
                                  height: 120,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                          ],
                        ),
                        child: busStopsResultsWidget,
                      );
                    },
              );
            }

            if (userSettingsSnapshot.hasError) {
              debugPrint("<=== ERROR ${userSettingsSnapshot.error} ===>");
              return Expanded(
                flex: 1,
                child: const ErrorText(
                  enableBackground: true,
                  icon: Symbols.settings_alert_rounded,
                ),
              );
            }

            return const Center(
              child: CircularProgressIndicator(strokeWidth: 3),
            );
          },
        ),
      ],
    );
  }
}
