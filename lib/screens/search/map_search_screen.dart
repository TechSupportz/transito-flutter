import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/search_provider.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/screens/search/search_screen.dart';
import 'package:transito/widgets/search/search_dialog.dart';

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key});

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> with TickerProviderStateMixin {
  late final AnimatedMapController _animatedMapController = AnimatedMapController(vsync: this);

  showClearAlertDialog(BuildContext context) => showDialog(
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

  // gets the user's current location
  Future<Position> getUserLocation() async {
    debugPrint(">>> Fetching user location");

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
      ),
    );

    return position;
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
                    minZoom: 10,
                    initialZoom: 17.5,
                    maxZoom: 18,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all &
                          ~InteractiveFlag.pinchMove &
                          ~InteractiveFlag.rotate,
                    ),
                    backgroundColor: appColors.brightness == Brightness.dark
                        ? Color(0xFF003653)
                        : Color(0xFF6DA7E3),
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
                      style: LocationMarkerStyle(headingSectorRadius: 80),
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SearchScreen(),
              settings: const RouteSettings(name: 'SearchScreen'),
            ),
          );
          HapticFeedback.selectionClick();
        },
        heroTag: 'searchIcon',
        child: const Icon(Icons.search_rounded),
      ),
    );
  }
}
