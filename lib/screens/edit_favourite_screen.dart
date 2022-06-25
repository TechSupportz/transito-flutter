import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:parent_child_checkbox/parent_child_checkbox.dart';
import 'package:provider/provider.dart';
import 'package:transito/models/favourite.dart';
import 'package:transito/providers/favourites_provider.dart';
import 'package:transito/screens/navbar_screens/main_screen.dart';

import '../models/app_colors.dart';

class EditFavouritesScreen extends StatefulWidget {
  const EditFavouritesScreen(
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
  State<EditFavouritesScreen> createState() => _EditFavouritesScreenState();
}

const checkBoxFontStyle = TextStyle(
  fontSize: 24,
);

class _EditFavouritesScreenState extends State<EditFavouritesScreen> {
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var favourites = context.read<FavouritesProvider>();
    var favouritesList = favourites.favouritesList;

    Map<String?, List<String?>> initialSelectedChildren = {
      'Bus Services': favouritesList
          .firstWhere((element) => element.busStopCode == widget.busStopCode)
          .services,
    };

    void updateFavorites() {
      // debugPrint('isParentSelected: ${ParentChildCheckbox.isParentSelected}');
      debugPrint('selectedChildren ${ParentChildCheckbox.selectedChildrens}');
      //TODO: add snackbar to notify favourite updated
      if (ParentChildCheckbox.selectedChildrens['Bus Services'].length != 0) {
        var selectedServices = ParentChildCheckbox.selectedChildrens['Bus Services']!;
        favourites.updateFavourite(
          Favourite(
              busStopCode: widget.busStopCode,
              busStopName: widget.busStopName,
              busStopAddress: widget.busStopAddress,
              latitude: widget.busStopLocation.latitude,
              longitude: widget.busStopLocation.longitude,
              services: selectedServices),
        );
        _showSnackBar('Updated favourites');
        print(favourites.favouritesList);
      } else {
        favourites.removeFavourite(widget.busStopCode);
        _showSnackBar('Removed favourites');
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(),
        ),
        (Route<dynamic> route) => false,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Favourites'),
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
                            color: AppColors.veryPurple, borderRadius: BorderRadius.circular(5)),
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
                  height: 8,
                ),
                const Text(
                  "Unselecting all the bus services will remove this bus stop from your favourites",
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
                      // initialParentValue: {'Bus Services': true},
                      initialChildrenValue: initialSelectedChildren,
                      parentCheckboxColor: AppColors.veryPurple,
                      childrenCheckboxColor: AppColors.veryPurple,
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
                  ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 42),
                      child: ElevatedButton(
                          onPressed: () => updateFavorites(), child: const Text("Save changes"))),
                  const SizedBox(
                    height: 8,
                  ),
                  ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 42),
                      child: OutlinedButton(
                          onPressed: () => Navigator.pop(context), child: const Text('Cancel')))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
