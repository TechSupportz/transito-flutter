import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:parent_child_checkbox/parent_child_checkbox.dart';
import 'package:provider/provider.dart';
import 'package:transito/models/favourite.dart';
import 'package:transito/providers/favourites_provider.dart';
import 'package:transito/providers/favourites_service.dart';
import 'package:transito/screens/navbar_screens/main_screen.dart';

import '../models/app_colors.dart';

class AddFavouritesScreen extends StatefulWidget {
  const AddFavouritesScreen(
      {Key? key,
      required this.busStopCode,
      required this.busStopName,
      required this.busStopAddress,
      required this.busStopLocation,
      required this.busServicesList})
      : super(key: key);
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
    var userId = context.read<User?>()?.uid;

    // access favourites provider
    var favourites = context.read<FavouritesProvider>();
    var favouritesList = favourites.favouritesList;

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
        _showSnackBar('Added to favourites');
        debugPrint('${favourites.favouritesList}');
        // navigate back to main screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        // if user somehow accesses this screen with a bus stop that already exists in favourites list, display snackbar to notify user
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
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
                            color: AppColors.accentColour, borderRadius: BorderRadius.circular(5)),
                        child: Text(widget.busStopCode, style: const TextStyle(fontSize: 16))),
                    Text(
                      widget.busStopAddress,
                      style: const TextStyle(
                          fontSize: 16, color: AppColors.kindaGrey, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 16,
                ),
                const Text(
                  "Select the bus services you would like to add to your favourites in this bus stop",
                  style: TextStyle(fontSize: 16, color: AppColors.kindaGrey),
                ),
                const SizedBox(
                  height: 16,
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ParentChildCheckbox(
                      parent: const Text("Bus Services", style: checkBoxFontStyle),
                      children: [
                        for (var service in widget.busServicesList)
                          Text(service, style: checkBoxFontStyle),
                      ],
                      parentCheckboxColor: AppColors.accentColour,
                      childrenCheckboxColor: AppColors.accentColour,
                      parentCheckboxScale: 1.35,
                      childrenCheckboxScale: 1.35,
                      gap: 2,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                      onPressed: () => addToFavorites(), child: const Text("Add to favourites")),
                  const SizedBox(
                    height: 8,
                  ),
                  OutlinedButton(
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
