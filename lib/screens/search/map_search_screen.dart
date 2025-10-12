import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_skeleton_ui/flutter_skeleton_ui.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/common_provider.dart';
import 'package:transito/global/providers/search_provider.dart';
import 'package:transito/models/api/transito/bus_stops.dart';
import 'package:transito/models/api/transito/nearby_bus_stops.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/models/secret.dart';
import 'package:transito/screens/bus_info/bus_stop_info_screen.dart';
import 'package:transito/screens/main/mrt_map_screen.dart';
import 'package:transito/widgets/common/app_symbol.dart';
import 'package:transito/widgets/search/search_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class MapSearchScreenController extends ChangeNotifier {
  void animateToUserLocation() => notifyListeners();
}

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key, this.controller});
  final MapSearchScreenController? controller;

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> with TickerProviderStateMixin {
  late final AnimatedMapController _animatedMapController = AnimatedMapController(vsync: this);
  final ValueNotifier<double> mapRotation = ValueNotifier<double>(0.0);
  late Future<LatLng> _initialCameraCenter;

  final ValueNotifier<List<Marker>> busStopMarkers = ValueNotifier<List<Marker>>([]);
  final ValueNotifier<bool> _isMarkersLoading = ValueNotifier<bool>(true);

  final ValueNotifier<String?> searchQuery = ValueNotifier<String?>(null);
  final ValueNotifier<Marker?> searchLocationPin = ValueNotifier<Marker?>(null);
  Timer? _debounce;

  Future<List<NearbyBusStop>> fetchNearbyBusStops(LatLng position) async {
    final response = await http.get(Uri.parse(
        '${Secret.API_URL}/bus-stops/nearby?latitude=${position.latitude}&longitude=${position.longitude}'));

    if (response.statusCode == 200) {
      debugPrint(">>> Nearby bus stops fetched");
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

      if (context.read<CommonProvider>().isUserCenter) {
        updateIsUserCenter(position);
      }

      List<NearbyBusStop> nearbyBusStops = await fetchNearbyBusStops(position);
      List<Marker> _newBusStopMarkers = nearbyBusStops.map((busStop) {
        BusStop busStopInfo = busStop.busStop;

        return Marker(
          key: ValueKey(busStopInfo.code),
          rotate: true,
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
              child: AppSymbol(
                Symbols.directions_bus_rounded,
                fill: true,
                color: Theme.of(context).colorScheme.onTertiary,
              ),
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
      rotation: 0,
    );
    if (mounted) context.read<CommonProvider>().setIsUserCenter(true);
  }

  void updateIsUserCenter(LatLng position) async {
    Position userPosition = await getUserLocation();
    if (!mounted) return;
    final common = context.read<CommonProvider>();
    final isCentered =
        userPosition.latitude == position.latitude && userPosition.longitude == position.longitude;

    common.setIsUserCenter(isCentered);
  }

  Marker buildLocationMarker(LatLng position) {
    return Marker(
      rotate: true,
      point: position,
      alignment: Alignment.topCenter,
      width: 40,
      height: 40,
      child: AppSymbol(
        Symbols.location_pin_sharp,
        fill: true,
        size: 48,
        color: Theme.of(context).colorScheme.primaryFixed,
        shadows: [
          Shadow(
            color: Theme.of(context).colorScheme.onPrimaryFixed,
            blurRadius: 32,
            offset: const Offset(0, 0),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    LatLng? initialMapPinLocation = context.read<CommonProvider>().initialMapPinLocation;

    if (initialMapPinLocation != null) {
      _initialCameraCenter = Future.value(initialMapPinLocation);
    } else {
      _initialCameraCenter = getUserLocation().then((position) {
        return LatLng(position.latitude, position.longitude);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      LatLng initialCameraCenter = await _initialCameraCenter;
      _onMapPositionChanged(initialCameraCenter);
    });

    widget.controller?.addListener(animateToUserLocation);
  }

  @override
  void dispose() {
    busStopMarkers.dispose();
    searchQuery.dispose();
    searchLocationPin.dispose();
    _isMarkersLoading.dispose();
    _animatedMapController.dispose();
    _debounce?.cancel();
    widget.controller?.removeListener(animateToUserLocation);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppColors appColors = context.watch<AppColors>();
    bool isUserCenter = context.watch<CommonProvider>().isUserCenter;
    bool supportsLiquidGlass = context.watch<CommonProvider>().supportsLiquidGlass;

    return Scaffold(
      backgroundColor: appColors.scheme.surfaceContainer,
      // displays the recent search list widget
      body: FutureBuilder(
          future: _initialCameraCenter,
          builder: (context, snapshot) {
            return Stack(
              children: [
                if (snapshot.connectionState == ConnectionState.waiting || snapshot.data == null)
                  SkeletonLine(
                    style: SkeletonLineStyle(height: double.infinity),
                  )
                else
                  FlutterMap(
                    mapController: _animatedMapController.mapController,
                    options: MapOptions(
                      initialCenter: LatLng(
                        snapshot.data!.latitude,
                        snapshot.data!.longitude,
                      ),
                      minZoom: 12,
                      initialZoom: 17.5,
                      maxZoom: 19,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.pinchMove,
                      ),
                      backgroundColor: appColors.brightness == Brightness.dark
                          ? Color(0xFF003653)
                          : Color(0xFF6DA7E3),
                      onPositionChanged: (camera, hasGesture) {
                        _onMapPositionChanged(camera.center);
                        mapRotation.value = camera.rotation;
                      },
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
                              rotate: true,
                              maxClusterRadius: 120,
                              disableClusteringAtZoom: 17,
                              spiderfyCluster: false,
                              zoomToBoundsOnClick: false,
                              centerMarkerOnClick: false,
                              animationsOptions:
                                  AnimationsOptions(zoom: Duration(milliseconds: 250)),
                              onClusterTap: (p0) {
                                _animatedMapController.animateTo(
                                  dest:
                                      LatLng(p0.bounds.center.latitude, p0.bounds.center.longitude),
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
                      ValueListenableBuilder<Marker?>(
                        valueListenable: searchLocationPin,
                        builder: (context, pin, child) {
                          return MarkerLayer(
                            markers: pin != null
                                ? [
                                    pin,
                                  ]
                                : [],
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
                      child: Column(
                        spacing: 16,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                useSafeArea: false,
                                builder: (context) => SearchDialog(
                                  initialQuery: searchQuery.value,
                                  onSearchCleared: () => searchQuery.value = null,
                                  onSearchSelected: (value) {
                                    searchLocationPin.value = buildLocationMarker(
                                      LatLng(value.latitude, value.longitude),
                                    );
                                    searchQuery.value = value.name;
                                    _animatedMapController.animateTo(
                                      dest: LatLng(value.latitude, value.longitude),
                                      zoom: 17.5,
                                    );
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
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  spacing: 8,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ValueListenableBuilder<String?>(
                                      valueListenable: searchQuery,
                                      builder: (context, query, child) {
                                        return Flexible(
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                icon: AnimatedSwitcher(
                                                  duration: const Duration(milliseconds: 200),
                                                  child: query == null
                                                      ? AppSymbol(
                                                          key: const ValueKey('searchIcon'),
                                                          Symbols.search_rounded,
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                        )
                                                      : AppSymbol(
                                                          key: const ValueKey('clearSearchIcon'),
                                                          Symbols.clear_rounded,
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                ),
                                                color:
                                                    Theme.of(context).colorScheme.onSurfaceVariant,
                                                style: ButtonStyle(
                                                    tapTargetSize:
                                                        MaterialTapTargetSize.shrinkWrap),
                                                onPressed: () {
                                                  searchQuery.value = null;
                                                  searchLocationPin.value = null;
                                                },
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Text(
                                                  query ?? 'Search for places...',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.fade,
                                                  softWrap: false,
                                                  style: TextStyle(
                                                    color: query == null
                                                        ? Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant
                                                        : Theme.of(context).colorScheme.onSurface,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
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
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MrtMapScreen(),
                                    settings: const RouteSettings(name: 'MrtMapScreen'),
                                  ),
                                ),
                                icon: const AppSymbol(Symbols.map_rounded, fill: true),
                                label: const Text('MRT Map'),
                              ),
                              ValueListenableBuilder(
                                valueListenable: mapRotation,
                                builder: (context, rotation, child) {
                                  int _cameraRotation = rotation.floor().abs();
                                  bool isRotated = !(_cameraRotation < 2 || _cameraRotation > 358);

                                  return AnimatedOpacity(
                                    opacity: isRotated ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 200),
                                    curve: Easing.standard,
                                    child: IconButton.filledTonal(
                                      style: ButtonStyle(
                                        backgroundColor: WidgetStateProperty.all(
                                          appColors.scheme.surfaceContainerHighest,
                                        ),
                                        elevation: WidgetStateProperty.all(4),
                                      ),
                                      onPressed: () {
                                        _animatedMapController.animateTo(
                                          zoom: 17.5,
                                          rotation: 0.0,
                                        );
                                      },
                                      icon: Transform.rotate(
                                        angle: rotation * (3.14 / 180),
                                        child: RotatedBox(
                                          quarterTurns:
                                              appColors.brightness == Brightness.light ? 2 : 0,
                                          child: SvgPicture.asset(
                                            "assets/icons/ui/compass_point.svg",
                                            colorFilter: ColorFilter.mode(
                                              Theme.of(context).colorScheme.tertiary,
                                              BlendMode.modulate,
                                            ),
                                          ),
                                        ),
                                      ),
                                      iconSize: 48,
                                    ),
                                  );
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                if (!supportsLiquidGlass)
                  IgnorePointer(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Theme.of(context).colorScheme.surfaceContainerLow,
                              Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLow
                                  .withValues(alpha: 0.0),
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
      floatingActionButton: !supportsLiquidGlass
          ? FloatingActionButton(
              onPressed: () {
                animateToUserLocation();
                HapticFeedback.lightImpact();
              },
              heroTag: 'searchIcon',
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeInOutCubicEmphasized,
                switchOutCurve: Curves.easeInOutCubicEmphasized,
                child: isUserCenter
                    ? const AppSymbol(
                        key: ValueKey("my_location"),
                        Symbols.my_location_rounded,
                        fill: true,
                      )
                    : const AppSymbol(
                        key: ValueKey("location_searching"),
                        Symbols.location_searching_rounded,
                      ),
              ),
            )
          : null,
    );
  }
}
