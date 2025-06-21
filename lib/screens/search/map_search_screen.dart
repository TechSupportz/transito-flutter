import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/search_provider.dart';
import 'package:transito/global/utils/unpack_polyline.dart';
import 'package:transito/models/app/app_colors.dart';

import 'search_screen.dart';

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key});

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  TextEditingController textFieldController = TextEditingController();

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
    AppColors appColors = context.read<AppColors>();

    return Scaffold(
      appBar: AppBar(title: const Text('Recent Searches'), actions: [
        // button to open the search interface
        IconButton(
          icon: const Icon(Icons.delete_rounded),
          onPressed: () => showClearAlertDialog(context),
        ),
      ]),
      // displays the recent search list widget
      body: FutureBuilder(
          future: getUserLocation(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting || snapshot.data == null) {
              return const Center(
                  child: CircularProgressIndicator()); // TODO: replace with skeleton
            }

            return FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(1.32119, 103.84407),
                minZoom: 10,
                initialZoom: 17.5,
                maxZoom: 18,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.pinchMove & ~InteractiveFlag.rotate,
                ),
                backgroundColor:
                    appColors.brightness == Brightness.dark ? Color(0xFF003653) : Color(0xFF6DA7E3),
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
                PolylineLayer(
                  simplificationTolerance: 0.6,
                  polylines: [
                    Polyline(
                      points: decodePolyline(
                              "s~`GmayxRa@a@VSDE@CFEHIPOBC@CA?@A\\Y@CnAmAHIBCDEDEDCDCJGFCJCFAHALAh@El@GXCXCF?TCAGC[?EB?JCPA@A@A?AEa@UaAAMB???")
                          .unpackPolyline(),
                      color: Colors.blue,
                      borderColor: Colors.white,
                      borderStrokeWidth: 5,
                      strokeWidth: 10,

                    )
                  ],
                ),
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
