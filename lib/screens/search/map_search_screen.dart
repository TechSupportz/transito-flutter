import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_skeleton_ui/flutter_skeleton_ui.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/common_provider.dart';
import 'package:transito/global/providers/search_provider.dart';
import 'package:transito/global/services/favourites_service.dart';
import 'package:transito/global/services/location_service.dart';
import 'package:transito/global/services/transito_api_service.dart';
import 'package:transito/models/api/transito/bus_stops.dart';
import 'package:transito/models/api/transito/nearby_bus_stops.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/models/app/app_typography.dart';
import 'package:transito/models/favourites/favourite.dart';
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
  static final LatLng _defaultCameraCenter = LatLng(1.3521, 103.8198);
  static const double _defaultZoom = 17.5;
  static const double _minZoom = 12;

  late final AnimatedMapController _animatedMapController = AnimatedMapController(vsync: this);
  final ValueNotifier<double> mapRotation = ValueNotifier<double>(0.0);
  late Future<LatLng> _initialCameraCenter;
  late Future<double> _initialCameraZoom;

  final ValueNotifier<Set<Marker>> busStopMarkers = ValueNotifier<Set<Marker>>({});
  final ValueNotifier<Set<Marker>> favouriteBusStopMarkers = ValueNotifier<Set<Marker>>({});
  final ValueNotifier<bool> _isMarkersLoading = ValueNotifier<bool>(true);
  final Map<String, Marker> _busStopMarkersByCode = <String, Marker>{};
  final Set<String> _favouriteBusStopCodes = <String>{};

  final ValueNotifier<String?> searchQuery = ValueNotifier<String?>(null);
  final ValueNotifier<Marker?> searchLocationPin = ValueNotifier<Marker?>(null);
  Timer? _debounce;
  StreamSubscription<List<Favourite>>? _favouritesSubscription;

  Future<List<NearbyBusStop>> fetchNearbyBusStops(LatLng position) async {
    final List<NearbyBusStop> stops = await TransitoApiService().getNearbyBusStops(position);
    debugPrint(">>> Nearby bus stops fetched");
    return stops;
  }

  void populateFavouriteBusStopMarkers(String userId) {
    _favouritesSubscription = FavouritesService().streamFavourites(userId).listen((favouritesList) {
      _favouriteBusStopCodes.clear();
      final favouriteMarkers = <Marker>{};

      for (final favourite in favouritesList) {
        _favouriteBusStopCodes.add(favourite.busStopCode);
        final marker = generateBusStopMarker(
          busStopCode: favourite.busStopCode,
          busStopName: favourite.busStopName,
          busStopAddress: favourite.busStopAddress,
          busStopLocation: favourite.busStopLocation,
          sources: favourite.sources,
          isFavourite: true,
        );
        _busStopMarkersByCode[favourite.busStopCode] = marker;
        favouriteMarkers.add(marker);
      }

      favouriteBusStopMarkers.value = favouriteMarkers;
    });
  }

  void _onMapPositionChanged(LatLng position) async {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      _isMarkersLoading.value = true;

      if (context.read<CommonProvider>().isUserCenter) {
        updateIsUserCenter(position);
      }

      List<NearbyBusStop> nearbyBusStops = await fetchNearbyBusStops(position);

      final nextMarkersByCode = <String, Marker>{};

      for (final nearby in nearbyBusStops) {
        final BusStop busStopInfo = nearby.busStop;
        final code = busStopInfo.code;

        if (_favouriteBusStopCodes.contains(code)) {
          continue;
        }

        final existing = _busStopMarkersByCode[code];
        if (existing != null) {
          nextMarkersByCode[code] = existing;
          continue;
        }

        nextMarkersByCode[code] = generateBusStopMarker(
          busStopCode: code,
          busStopName: busStopInfo.name,
          busStopAddress: busStopInfo.roadName,
          sources: busStopInfo.sources,
          busStopLocation: LatLng(
            busStopInfo.latitude,
            busStopInfo.longitude,
          ),
          isFavourite: false,
        );
      }

      _busStopMarkersByCode
        ..clear()
        ..addAll(nextMarkersByCode);
      busStopMarkers.value = nextMarkersByCode.values.toSet();
      _isMarkersLoading.value = false;
    });
  }

  Marker generateBusStopMarker({
    required String busStopCode,
    required String busStopName,
    required String busStopAddress,
    BusStopProviderSources? sources,
    required LatLng busStopLocation,
    bool isFavourite = false,
  }) {
    return Marker(
      key: ValueKey(busStopCode),
      rotate: true,
      width: 40,
      height: 40,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BusStopInfoScreen(
                code: busStopCode,
                name: busStopName,
                address: busStopAddress,
                busStopLocation: busStopLocation,
                sources: sources,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: isFavourite
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.tertiary,
            borderRadius: isFavourite ? BorderRadius.circular(8) : null,
            shape: isFavourite ? BoxShape.rectangle : BoxShape.circle,
          ),
          child: AppSymbol(
            Symbols.directions_bus_rounded,
            fill: true,
            color: isFavourite
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onTertiary,
          ),
        ),
      ),
      point: busStopLocation,
    );
  }

  showClearAlertDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear recent searches?'),
        content: const Text(
          'Are you sure you want to clear your recent searches? \n\nThis action cannot be undone.',
        ),
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
          ),
        ],
      ),
    );
  }

  Future<void> animateToUserLocation() async {
    final Position? position = await LocationService().getCurrentPosition(userInitiated: true);
    if (position == null) {
      if (mounted) context.read<CommonProvider>().setIsUserCenter(false);
      return;
    }

    _animatedMapController.animateTo(
      dest: LatLng(position.latitude, position.longitude),
      zoom: _defaultZoom,
      rotation: 0,
    );
    if (mounted) context.read<CommonProvider>().setIsUserCenter(true);
  }

  void updateIsUserCenter(LatLng position) async {
    final Position? userPosition = await LocationService().getCurrentPosition();
    if (!mounted) return;
    final common = context.read<CommonProvider>();
    if (userPosition == null) {
      common.setIsUserCenter(false);
      return;
    }

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
    var userId = context.read<User?>()?.uid;

    if (userId != null) populateFavouriteBusStopMarkers(userId);

    if (initialMapPinLocation != null) {
      _initialCameraCenter = Future.value(initialMapPinLocation);
      _initialCameraZoom = Future.value(_defaultZoom);
    } else {
      _initialCameraCenter = LocationService().getCurrentPosition().then((position) {
        if (position == null) {
          return _defaultCameraCenter;
        }

        return LatLng(position.latitude, position.longitude);
      });
      _initialCameraZoom = LocationService().getCurrentPosition().then((position) {
        if (position == null) {
          return _minZoom;
        }

        return _defaultZoom;
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
    favouriteBusStopMarkers.dispose();
    searchQuery.dispose();
    searchLocationPin.dispose();
    _isMarkersLoading.dispose();
    _animatedMapController.dispose();
    _debounce?.cancel();
    _favouritesSubscription?.cancel();
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
        future: Future.wait([_initialCameraCenter, _initialCameraZoom]),
        builder: (context, snapshot) {
          final LatLng? initialCameraCenter = snapshot.data?[0] as LatLng?;
          final double? initialCameraZoom = snapshot.data?[1] as double?;

          return Stack(
            children: [
              if (snapshot.connectionState == ConnectionState.waiting ||
                  initialCameraCenter == null ||
                  initialCameraZoom == null)
                SkeletonLine(
                  style: SkeletonLineStyle(height: double.infinity),
                )
              else
                FlutterMap(
                  mapController: _animatedMapController.mapController,
                  options: MapOptions(
                    initialCenter: LatLng(
                      initialCameraCenter.latitude,
                      initialCameraCenter.longitude,
                    ),
                    minZoom: _minZoom,
                    initialZoom: initialCameraZoom,
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
                      positionStream: const LocationMarkerDataStreamFactory()
                          .fromGeolocatorPositionStream(
                            stream: LocationService().positionStream,
                          ),
                      style: LocationMarkerStyle(),
                    ),
                    // Regular bus stop markers
                    ValueListenableBuilder<Set<Marker>>(
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
                            animationsOptions: AnimationsOptions(zoom: Duration(milliseconds: 250)),
                            onClusterTap: (p0) {
                              _animatedMapController.animateTo(
                                dest: LatLng(p0.bounds.center.latitude, p0.bounds.center.longitude),
                                zoom: 17,
                              );
                            },
                            size: const Size(40, 40),
                            markers: markers.toList(),
                            builder: (context, clusterMarkers) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.tertiary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    clusterMarkers.length.toString(),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onTertiary,
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
                    // Favourite bus stop markers (separate layer)
                    ValueListenableBuilder<Set<Marker>>(
                      valueListenable: favouriteBusStopMarkers,
                      builder: (context, markers, child) {
                        return MarkerClusterLayerWidget(
                          options: MarkerClusterLayerOptions(
                            rotate: true,
                            maxClusterRadius: 120,
                            disableClusteringAtZoom: 17,
                            spiderfyCluster: false,
                            zoomToBoundsOnClick: false,
                            centerMarkerOnClick: false,
                            animationsOptions: AnimationsOptions(zoom: Duration(milliseconds: 250)),
                            onClusterTap: (p0) {
                              _animatedMapController.animateTo(
                                dest: LatLng(p0.bounds.center.latitude, p0.bounds.center.longitude),
                                zoom: 17,
                              );
                            },
                            size: const Size(40, 40),
                            markers: markers.toList(),
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
                          textStyle: AppTypography.labelSmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                          prependCopyright: false,
                        ),
                      ],
                      alignment: AttributionAlignment.bottomLeft,
                    ),
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
                            elevation: 5,
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
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.onSurfaceVariant,
                                                      )
                                                    : AppSymbol(
                                                        key: const ValueKey('clearSearchIcon'),
                                                        Symbols.clear_rounded,
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.onSurfaceVariant,
                                                      ),
                                              ),
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              style: ButtonStyle(
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
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
                                                      ? Theme.of(
                                                          context,
                                                        ).colorScheme.onSurfaceVariant
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
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(appColors.scheme.primary),
                                foregroundColor: WidgetStateProperty.all(
                                  appColors.scheme.onPrimary,
                                ),
                                elevation: WidgetStateProperty.all(3),
                              ),
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
                                        rotation: 0.0,
                                        zoom:
                                            _animatedMapController.mapController.camera.zoom + 0.25,
                                      );
                                    },
                                    icon: Transform.rotate(
                                      angle: rotation * (3.14 / 180),
                                      child: RotatedBox(
                                        quarterTurns: appColors.brightness == Brightness.light
                                            ? 2
                                            : 0,
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
                        ),
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
                            Theme.of(
                              context,
                            ).colorScheme.surfaceContainerLow.withValues(alpha: 0.0),
                          ],
                          stops: [0, 0.01],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
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
