import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:parent_child_checkbox/parent_child_checkbox.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/favourites_provider.dart';
import 'package:transito/global/services/favourites_service.dart';
import 'package:transito/global/services/transito_api_service.dart';
import 'package:transito/models/api/transito/bus_stops.dart';
import 'package:transito/models/app/app_typography.dart';
import 'package:transito/models/favourites/favourite.dart';
import 'package:transito/screens/navigator_screen.dart';

class AddFavouritesScreen extends StatefulWidget {
  const AddFavouritesScreen({
    super.key,
    required this.busStopCode,
    required this.busStopName,
    required this.busStopAddress,
    required this.busStopLocation,
    required this.busServicesList,
    required this.sources,
  });
  final String busStopCode;
  final String busStopName;
  final String busStopAddress;
  final LatLng busStopLocation;
  final List<String> busServicesList;
  final BusStopProviderSources? sources;

  @override
  State<AddFavouritesScreen> createState() => _AddFavouritesScreenState();
}

const checkBoxFontStyle = TextStyle(
  fontSize: 24,
);

class _AddFavouritesScreenState extends State<AddFavouritesScreen> {
  bool _isAddingFavourite = false;

  // function to display snackbar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<Favourite> _buildFavourite(List<String?> selectedServices) async {
    try {
      final BusStop currentBusStop = await TransitoApiService().getBusStop(widget.busStopCode);

      return Favourite(
        busStopCode: currentBusStop.code,
        busStopName: currentBusStop.name,
        busStopAddress: currentBusStop.roadName,
        busStopLocation: LatLng(currentBusStop.latitude, currentBusStop.longitude),
        services: selectedServices,
        sources: currentBusStop.sources,
      );
    } catch (error) {
      debugPrint('Failed to refresh bus stop before adding favourite: $error');
      return Favourite(
        busStopCode: widget.busStopCode,
        busStopName: widget.busStopName,
        busStopAddress: widget.busStopAddress,
        busStopLocation: widget.busStopLocation,
        services: selectedServices,
        sources: widget.sources ?? BusStopProviderSources(lta: widget.busStopCode),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String? userId = context.read<User?>()?.uid;

    // access favourites provider
    FavouritesProvider favourites = context.read<FavouritesProvider>();
    List<Favourite> favouritesList = favourites.favouritesList;

    Future<void> addToFavorites() async {
      if (_isAddingFavourite) {
        return;
      }

      // debugPrint('isParentSelected: ${ParentChildCheckbox.isParentSelected}');
      debugPrint('selectedChildren ${ParentChildCheckbox.selectedChildrens}');

      List<String?> selectedServices = ParentChildCheckbox.selectedChildrens['Bus Services']!;

      // check if any bus services are selected
      if (selectedServices.isEmpty) {
        _showSnackBar("Please select at least one bus service");
        return;
      }

      // check if bus stop already exists in favourites list
      if (favouritesList.every((element) => element.busStopCode != widget.busStopCode)) {
        // retrieve the selected services and add it to the favourites list
        setState(() {
          _isAddingFavourite = true;
        });

        bool didNavigate = false;
        try {
          final Favourite favourite = await _buildFavourite(selectedServices);
          if (!context.mounted) {
            return;
          }

          await FavouritesService().addFavourite(favourite, userId!);
          if (!context.mounted) {
            return;
          }

          // display snackbar to notify user that favourite has been added
          _showSnackBar('Added ${widget.busStopName} to favourites');
          debugPrint('${favourites.favouritesList}');
          // navigate back to main screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const NavigatorScreen()),
            (Route<dynamic> route) => false,
          );
          didNavigate = true;
        } finally {
          if (mounted && !didNavigate) {
            setState(() {
              _isAddingFavourite = false;
            });
          }
        }
      } else {
        // if user somehow accesses this screen with a bus stop that already exists in favourites list, display snackbar to notify user
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const NavigatorScreen()),
          (Route<dynamic> route) => false,
        );
        _showSnackBar('Something went wrong...');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add to Favourites'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.busStopName,
                  style: AppTypography.pageTitle,
                ),
                const SizedBox(
                  height: 4,
                ),
                Row(
                  spacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.busStopCode,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      widget.busStopAddress,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 16,
                ),
                Text(
                  "Select the bus services you would like to add to your favourites in this bus stop",
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
              ],
            ),
            Expanded(
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surface.withValues(alpha: 0.0),
                      Theme.of(context).colorScheme.surface.withValues(alpha: 0.0),
                      Theme.of(context).colorScheme.surface,
                    ],
                    stops: [0.0, 0.05, 0.95, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstOut,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Column(
                    children: [
                      ParentChildCheckbox(
                        parent: const Text("Bus Services", style: checkBoxFontStyle),
                        parentCheckboxScale: 1.35,
                        childrenCheckboxScale: 1.35,
                        gap: 2,
                        children: [
                          for (var service in widget.busServicesList)
                            Text(service, style: checkBoxFontStyle),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: () => addToFavorites(),
                    child: AnimatedSwitcher(
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                      duration: const Duration(milliseconds: 175),
                      child: _isAddingFavourite
                          ? SizedBox(
                              height: 16,
                              width: 16,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : const Text("Add to favourites"),
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  FilledButton.tonal(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
