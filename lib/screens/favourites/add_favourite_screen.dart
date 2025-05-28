import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:parent_child_checkbox/parent_child_checkbox.dart';
import 'package:provider/provider.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/models/favourites/favourite.dart';
import 'package:transito/global/providers/favourites_provider.dart';
import 'package:transito/global/services/favourites_service.dart';
import 'package:transito/screens/navigator_screen.dart';

class AddFavouritesScreen extends StatefulWidget {
  const AddFavouritesScreen({
    super.key,
    required this.busStopCode,
    required this.busStopName,
    required this.busStopAddress,
    required this.busStopLocation,
    required this.busServicesList,
  });
  final String busStopCode;
  final String busStopName;
  final String busStopAddress;
  final LatLng busStopLocation;
  final List<String> busServicesList;

  @override
  State<AddFavouritesScreen> createState() => _AddFavouritesScreenState();
}

const checkBoxFontStyle = TextStyle(
  fontSize: 24,
);

class _AddFavouritesScreenState extends State<AddFavouritesScreen> {
  // function to display snackbar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? userId = context.read<User?>()?.uid;
    AppColors appColors = context.read<AppColors>();

    // access favourites provider
    FavouritesProvider favourites = context.read<FavouritesProvider>();
    List<Favourite> favouritesList = favourites.favouritesList;

    void addToFavorites() {
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
        FavouritesService().addFavourite(
          Favourite(
            busStopCode: widget.busStopCode,
            busStopName: widget.busStopName,
            busStopAddress: widget.busStopAddress,
            busStopLocation: widget.busStopLocation,
            services: selectedServices,
          ),
          userId!,
        );
        // display snackbar to notify user that favourite has been added
        _showSnackBar('Added ${widget.busStopName} to favourites');
        debugPrint('${favourites.favouritesList}');
        // navigate back to main screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const NavigatorScreen()),
          (Route<dynamic> route) => false,
        );
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
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        widget.busStopCode,
                        style:
                            TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ),
                    Text(
                      widget.busStopAddress,
                      style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 16,
                ),
                Text(
                  "Select the bus services you would like to add to your favourites in this bus stop",
                  style: TextStyle(
                      fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(
                  height: 8,
                ),
              ],
            ),
            Expanded(
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xFF0c0c0c),
                      Colors.transparent,
                      Colors.transparent,
                      Color(0xFF0c0c0c)
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
                      onPressed: () => addToFavorites(), child: const Text("Add to favourites")),
                  const SizedBox(
                    height: 8,
                  ),
                  FilledButton.tonal(
                      onPressed: () => Navigator.pop(context), child: const Text('Cancel'))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
