import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/search_provider.dart';
import 'package:transito/models/api/transito/bus_stops.dart';
import 'package:transito/models/api/transito/nearby_bus_stops.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/models/secret.dart';
import 'package:transito/screens/bus_info/bus_stop_info_screen.dart';
import 'package:transito/widgets/search/search_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key});

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> with TickerProviderStateMixin {
  late final AnimatedMapController _animatedMapController = AnimatedMapController(vsync: this);
  Timer? _debounce;
  final ValueNotifier<List<Marker>> busStopMarkers = ValueNotifier<List<Marker>>([]);
  final ValueNotifier<bool> _isMarkersLoading = ValueNotifier<bool>(true);

  Future<List<NearbyBusStop>> fetchNearbyBusStops(LatLng position) async {
    final response = await http.get(Uri.parse(
        '${Secret.API_URL}/bus-stops/nearby?latitude=${position.latitude}&longitude=${position.longitude}'));

    if (response.statusCode == 200) {
      debugPrint("Nearby bus stops fetched");
      return NearbyBusStopsApiResponse.fromJson(jsonDecode(response.body)).data;
    } else {
      debugPrint("Failed to fetch nearby bus stops");
      throw Exception('Failed to fetch nearby bus stops');
    }
  }

  void _onMapPositionChanged(LatLng position) async {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      _isMarkersLoading.value = true;
      List<NearbyBusStop> nearbyBusStops = await fetchNearbyBusStops(position);

      List<Marker> _newBusStopMarkers = nearbyBusStops.map((busStop) {
        BusStop busStopInfo = busStop.busStop;

        return Marker(
          key: ValueKey(busStopInfo.code),
          width: 40,
          height: 40,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BusStopInfoScreen(
                    code: busStopInfo.code,
                    name: busStopInfo.name,
                    address: busStopInfo.roadName,
                    busStopLocation: LatLng(busStopInfo.latitude, busStopInfo.longitude),
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.directions_bus_rounded,
                  color: Theme.of(context).colorScheme.onTertiary),
            ),
          ),
          point: LatLng(busStop.busStop.latitude, busStop.busStop.longitude),
        );
      }).toList();

      busStopMarkers.value = _newBusStopMarkers;
      _isMarkersLoading.value = false;
    });
  }

  showClearAlertDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear recent searches?'),
        content: const Text(
            'Are you sure you want to clear your recent searches? \n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Provider.of<SearchProvider>(context, listen: false).clearAllRecentSearches();
              Navigator.pop(context);
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.error,
              ),
            ),
            child: const Text('Clear'),
          )
        ],
      ),
    );
  }

  // gets the user's current location
  Future<Position> getUserLocation({bool? populateMarkers}) async {
    debugPrint(">>> Fetching user location");

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
      ),
    );

    return position;
  }

  Future<void> animateToUserLocation() async {
    Position position = await getUserLocation();
    _animatedMapController.animateTo(
      dest: LatLng(position.latitude, position.longitude),
      zoom: 17.5,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Position position = await getUserLocation();
      _onMapPositionChanged(LatLng(position.latitude, position.longitude));
    });
  }

  @override
  void dispose() {
    busStopMarkers.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppColors appColors = context.watch<AppColors>();

    return Scaffold(
      backgroundColor: appColors.scheme.surfaceContainer,
      // displays the recent search list widget
      body: FutureBuilder(
          future: getUserLocation(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting || snapshot.data == null) {
              return const Center(
                child: CircularProgressIndicator(),
              ); // TODO: replace with skeleton
            }

            return Stack(
              children: [
                FlutterMap(
                  mapController: _animatedMapController.mapController,
                  options: MapOptions(
                    initialCenter: LatLng(snapshot.data!.latitude, snapshot.data!.longitude),
                    minZoom: 16.5,
                    initialZoom: 17.5,
                    maxZoom: 19,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all &
                          ~InteractiveFlag.pinchMove &
                          ~InteractiveFlag.rotate,
                    ),
                    backgroundColor: appColors.brightness == Brightness.dark
                        ? Color(0xFF003653)
                        : Color(0xFF6DA7E3),
                    onPositionChanged: (camera, hasGesture) => _onMapPositionChanged(camera.center),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://www.onemap.gov.sg/maps/tiles/${appColors.brightness == Brightness.dark ? 'Night_HD' : 'Default_HD'}/{z}/{x}/{y}.png",
                      fallbackUrl:
                          "https://www.onemap.gov.sg/maps/tiles/${appColors.brightness == Brightness.dark ? 'Night' : 'Default'}/{z}/{x}/{y}.png",
                      userAgentPackageName: 'com.tnitish.transito',
                      errorImage: const AssetImage('assets/images/mapError.png'),
                    ),
                    CurrentLocationLayer(
                      style: LocationMarkerStyle(),
                    ),
                    ValueListenableBuilder<List<Marker>>(
                      valueListenable: busStopMarkers,
                      builder: (context, markers, child) {
                        return MarkerClusterLayerWidget(
                          options: MarkerClusterLayerOptions(
                            maxClusterRadius: 120,
                            disableClusteringAtZoom: 17,
                            spiderfyCluster: false,
                            zoomToBoundsOnClick: false,
                            centerMarkerOnClick: false,
                            animationsOptions: AnimationsOptions(zoom: Duration(milliseconds: 250)),
                            onClusterTap: (p0) {
                              _animatedMapController.animateTo(
                                dest: LatLng(p0.bounds.center.latitude, p0.bounds.center.longitude),
                                zoom: 18.5,
                              );
                            },
                            size: const Size(40, 40),
                            markers: markers,
                            builder: (context, clusterMarkers) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    clusterMarkers.length.toString(),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    RichAttributionWidget(
                      showFlutterMapAttribution: false,
                      popupBorderRadius: BorderRadius.circular(8),
                      attributions: [
                        LogoSourceAttribution(
                          Image.network(
                            "https://www.onemap.gov.sg/web-assets/images/logo/om_logo.png",
                          ),
                        ),
                        TextSourceAttribution(
                          "OneMap © contributors",
                          prependCopyright: false,
                          onTap: () => launchUrl(Uri.parse("https://www.onemap.gov.sg/")),
                        ),
                        TextSourceAttribution(
                          "Singapore Land Authority",
                          prependCopyright: false,
                          onTap: () => launchUrl(Uri.parse("https://www.sla.gov.sg/")),
                        ),
                        TextSourceAttribution(
                          "Powered by 'flutter_map'",
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                          prependCopyright: false,
                        ),
                      ],
                      alignment: AttributionAlignment.bottomLeft,
                    )
                  ],
                ),
                SafeArea(
                  left: false,
                  right: false,
                  bottom: false,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              useSafeArea: false,
                              builder: (context) => SearchDialog(
                                onSearchSelected: (value) => {
                                  _animatedMapController.animateTo(
                                    dest: LatLng(value.latitude, value.longitude),
                                  ),
                                },
                              ),
                            );
                            HapticFeedback.selectionClick();
                          },
                          child: Material(
                            borderRadius: BorderRadius.circular(64),
                            elevation: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(64),
                              ),
                              height: 56,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_rounded,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'Search for places...',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontSize: 16,
                                        ),
                                      )
                                    ],
                                  ),
                                  ValueListenableBuilder<bool>(
                                    valueListenable: _isMarkersLoading,
                                    builder: (context, isLoading, child) {
                                      return SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          value: isLoading ? null : 0.0,
                                          color: Theme.of(context).colorScheme.primary,
                                          strokeWidth: 2.0,
                                          strokeCap: StrokeCap.round,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )),
                  ),
                ),
                IgnorePointer(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Theme.of(context).colorScheme.surfaceContainer,
                            Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: 0.0),
                          ],
                          stops: [0, 0.01],
                        ),
                      ),
                    ),
                  ),
                )
              ],
            );
          }),
      // floating action button to clear the recent searches list by calling a function in the search provider
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          animateToUserLocation();
          HapticFeedback.lightImpact();
        },
        heroTag: 'searchIcon',
        child: const Icon(Icons.near_me_rounded),
      ),
    );
  }
}
