import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_skeleton_ui/flutter_skeleton_ui.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:jiffy/jiffy.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/services/favourites_service.dart';
import 'package:transito/global/services/settings_service.dart';
import 'package:transito/global/utils/scroll_to_content.dart';
import 'package:transito/models/api/lta/arrival_info.dart';
import 'package:transito/models/api/transito/bus_services.dart';
import 'package:transito/models/secret.dart';
import 'package:transito/models/user/user_settings.dart';
import 'package:transito/screens/favourites/add_favourite_screen.dart';
import 'package:transito/screens/favourites/edit_favourite_screen.dart';
import 'package:transito/widgets/bus_info/bus_service_chip.dart';
import 'package:transito/widgets/bus_timings/bus_timing_row.dart';
import 'package:transito/widgets/common/bus_timing_guide.dart';
import 'package:transito/widgets/common/error_text.dart';

import 'bus_stop_info_screen.dart';

class BusTimingScreen extends StatefulWidget {
  const BusTimingScreen({
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
  final List<String>? services;
  final LatLng busStopLocation;

  @override
  State<BusTimingScreen> createState() => _BusTimingScreenState();
}

class _BusTimingScreenState extends State<BusTimingScreen> with SingleTickerProviderStateMixin {
  late Future<BusArrivalInfo> futureBusArrivalInfo;
  late Future<List<String>> futureServices;
  late AnimationController _animationController;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey expansionTileKey = GlobalKey();
  bool isFabVisible = true;
  bool isAddedToFavourites = false;
  bool sortByArrivalTime = false;
  late Timer timer;

  // function to get the user's location
  Future<Position> getUserLocation() async {
    debugPrint("Fetching user location");
    Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best));
    debugPrint('$position');
    return position;
  }

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

  // function to fetch bus arrival info
  Future<BusArrivalInfo> fetchArrivalTimings() async {
    debugPrint("Fetching arrival timings");
    // gets response from api
    final response = await http.get(
        Uri.parse(
            'https://datamall2.mytransport.sg/ltaodataservice/v3/BusArrival?BusStopCode=${widget.code}'),
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

  // function to properly sort the bus arrival info according to the Bus Service number
  BusArrivalInfo sortBusArrivalInfo(BusArrivalInfo value) {
    var _value = value;

    if (sortByArrivalTime) {
      _value.services.sort((a, b) {
        if (a.nextBus.estimatedArrival == null ||
            b.nextBus.estimatedArrival == null ||
            a.nextBus.estimatedArrival == "" ||
            b.nextBus.estimatedArrival == "") {
          return 0;
        }

        return Jiffy.parse(a.nextBus.estimatedArrival!.split("+")[0]).isAfter(
          Jiffy.parse(b.nextBus.estimatedArrival!.split("+")[0]),
        )
            ? 1
            : 0;
      });

      return _value;
    }

    _value.services.sort((a, b) => compareNatural(a.serviceNum, b.serviceNum));

    return _value;
  }

  // function to get the list of bus services that are currently operating at that bus stop and route to the add favourites screen
  Future<void> goToAddFavouritesScreen(BuildContext context) async {
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
  Future<void> goToEditFavouritesScreen(BuildContext context) async {
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

  // function to hide the fab when the user is scrolling down the list to avoid blocking content
  bool hideFabOnScroll(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.forward) {
      !isFabVisible ? setState(() => isFabVisible = true) : null;
    } else if (notification.direction == ScrollDirection.reverse) {
      isFabVisible ? setState(() => isFabVisible = false) : null;
    }

    return true;
  }

  Future<void> goToBusStopInfoScreen(BuildContext context) async {
    List<String> services = await futureServices;

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusStopInfoScreen(
          code: widget.code,
          name: widget.name,
          address: widget.address,
          busStopLocation: widget.busStopLocation,
          services: services,
        ),
        settings: const RouteSettings(name: 'BusStopInfoScreen'),
      ),
    );
  }

  void showTimingGuideDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Bus Timing Guide"),
          content: const BusTimingGuide(),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  // initialise bus arrival info and start the timer to automatically re-fetch the bus arrival info every 30 seconds
  @override
  void initState() {
    super.initState();
    // print(widget.busStopLocation);
    futureBusArrivalInfo = fetchArrivalTimings().then((value) => sortBusArrivalInfo(value));
    futureServices = fetchServices();
    timer = Timer.periodic(
        const Duration(seconds: 30),
        (Timer t) => setState(
              () {
                futureBusArrivalInfo =
                    fetchArrivalTimings().then((value) => sortBusArrivalInfo(value));
              },
            ));

    var userId = context.read<User?>()?.uid;
    FavouritesService().isAddedToFavourites(widget.code, userId!).then((value) {
      setState(() {
        isAddedToFavourites = value;
      });
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = context.watch<User?>();
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => goToBusStopInfoScreen(context),
          child: Text(widget.name),
        ),
        actions: [
          IconButton(
            icon: Row(
              children: [
                const Icon(Icons.arrow_downward_rounded),
                sortByArrivalTime
                    ? const Icon(Icons.onetwothree_rounded, size: 32,)
                    : const Icon(Icons.access_time_rounded),
              ],
            ),
            onPressed: () {
              setState(() {
                sortByArrivalTime = !sortByArrivalTime;
                futureBusArrivalInfo = fetchArrivalTimings().then(
                  (value) => sortBusArrivalInfo(value),
                );
              });
            },
          ),
          // display different IconButtons depending on whether the bus stop is a favourite or not
          isAddedToFavourites
              ? IconButton(
                  icon: const Icon(Icons.favorite_rounded),
                  onPressed: () => goToEditFavouritesScreen(context),
                )
              : IconButton(
                  icon: const Icon(Icons.favorite_border_rounded),
                  onPressed: () => goToAddFavouritesScreen(context),
                ),
          IconButton(
            icon: const Icon(
              Icons.help_outline_rounded,
            ),
            onPressed: () => showTimingGuideDialog(),
          ),
        ],
      ),
      body: StreamBuilder(
          stream: SettingsService().streamSettings(user?.uid),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              UserSettings userSettings = snapshot.data as UserSettings;
              return FutureBuilder(
                future: futureBusArrivalInfo,
                builder:
                    (BuildContext context, AsyncSnapshot<BusArrivalInfo> busArrivalInfoSnapshot) {
                  Widget arrivalInfoResults = Container();

                  // check if the snapshot has data, if not then display a loading indicator
                  if (busArrivalInfoSnapshot.hasData) {
                    // notification listener to hide the fab when the user is scrolling down the list
                    arrivalInfoResults = NotificationListener<UserScrollNotification>(
                      onNotification: (notification) => hideFabOnScroll(notification),
                      child: busArrivalInfoSnapshot.data!.services.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  Jiffy.now().hour >= 5
                                      ? '🦥 All the buses are lepaking 🦥'
                                      : "💤 Buses are sleeping 💤",
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                setState(() {
                                  futureBusArrivalInfo = fetchArrivalTimings().then(
                                    (value) => sortBusArrivalInfo(value),
                                  );
                                });
                              },
                              child: ListView(
                                controller: _scrollController,
                                padding:
                                    const EdgeInsets.only(top: 12, bottom: 32, left: 12, right: 12),
                                children: [
                                  ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, int index) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: BusTimingRow(
                                            busStopCode: widget.code,
                                            serviceInfo:
                                                busArrivalInfoSnapshot.data!.services[index],
                                            userLatLng: widget.busStopLocation,
                                            isETAminutes: userSettings.isETAminutes,
                                          ),
                                        );
                                      },
                                      separatorBuilder: (BuildContext context, int index) =>
                                          const Divider(),
                                      itemCount: busArrivalInfoSnapshot.data!.services.length),
                                  FutureBuilder(
                                      future: futureServices,
                                      builder: (context, servicesSnapshot) {
                                        Widget nonOperationalServicesResults = Container();
                                        final currOperatingServices = busArrivalInfoSnapshot
                                            .data!.services
                                            .map((e) => e.serviceNum)
                                            .toList();

                                        if (servicesSnapshot.hasData) {
                                          final services = servicesSnapshot.data as List<String>;
                                          final nonOperatingServices = services
                                              .where((element) =>
                                                  !currOperatingServices.contains(element))
                                              .toList();

                                          if (nonOperatingServices.isEmpty) {
                                            return const SizedBox.shrink();
                                          }

                                          nonOperationalServicesResults = Opacity(
                                            opacity: 0.65,
                                            child: Column(
                                              children: [
                                                Theme(
                                                  data: Theme.of(context).copyWith(
                                                    splashFactory: NoSplash.splashFactory,
                                                    highlightColor: Colors.transparent,
                                                  ),
                                                  child: ExpansionTile(
                                                    key: expansionTileKey,
                                                    title: const Text(
                                                      "Non-operational services",
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    controlAffinity:
                                                        ListTileControlAffinity.leading,
                                                    leading: const Icon(
                                                      Icons.info_outline_rounded,
                                                    ),
                                                    onExpansionChanged: (value) {
                                                      if (value) {
                                                        scrollToSelectedContent(expansionTileKey);
                                                      }
                                                    },
                                                    shape: const Border(),
                                                    children: [
                                                      Wrap(
                                                        spacing: 8,
                                                        runSpacing: 8,
                                                        direction: Axis.horizontal,
                                                        alignment: WrapAlignment.start,
                                                        children:
                                                            nonOperatingServices //TODO - This list should contain the origin and destination of the bus service. (Minimally the origin)
                                                                .map(
                                                                  (service) => BusServiceChip(
                                                                    busServiceNumber: service,
                                                                    currentStopCode: widget.code,
                                                                    isOperating: true,
                                                                  ),
                                                                )
                                                                .toList(),
                                                      )
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          );
                                        } else if (servicesSnapshot.hasError) {
                                          nonOperationalServicesResults = const ErrorText();
                                        }

                                        return Skeleton(
                                            isLoading: servicesSnapshot.connectionState ==
                                                ConnectionState.waiting,
                                            skeleton: Container(),
                                            child: nonOperationalServicesResults);
                                      })
                                ],
                              ),
                            ),
                    );
                  } else if (busArrivalInfoSnapshot.hasError) {
                    // return Text("${snapshot.error}");
                    debugPrint("<=== ERROR ${busArrivalInfoSnapshot.error} ===>");
                    arrivalInfoResults = const ErrorText();
                  }

                  Animation<double> _animation =
                      Tween(begin: 0.0, end: 0.5).animate(_animationController);
                  _animationController.forward();

                  return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      child: busArrivalInfoSnapshot.connectionState == ConnectionState.waiting &&
                              !busArrivalInfoSnapshot.hasData
                          ? FadeTransition(
                              opacity: _animation,
                              child: const SkeletonLine(
                                style: SkeletonLineStyle(
                                  height: double.infinity,
                                ),
                              ),
                            )
                          : arrivalInfoResults);
                },
              );
            } else if (snapshot.hasError) {
              // return Text("${snapshot.error}");
              debugPrint("<=== ERROR ${snapshot.error} ===>");
              return const ErrorText();
            } else {
              return const Center();
            }
          }),
      floatingActionButton: isFabVisible
          // re-fetch data when user taps the refresh button
          ? FloatingActionButton(
              onPressed: () => setState(() {
                futureBusArrivalInfo = fetchArrivalTimings().then(
                  (value) => sortBusArrivalInfo(value),
                );
                HapticFeedback.selectionClick();
              }),
              heroTag: "busTimingFAB",
              enableFeedback: true,
              child: const Icon(Icons.refresh_rounded, size: 28),
            )
          : null,
    );
  }

  // dispose of the timer when user leaves the screen
  @override
  void dispose() {
    timer.cancel();
    debugPrint("Timer cancelled");
    super.dispose();
  }
}
