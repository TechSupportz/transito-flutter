import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:parent_child_checkbox/parent_child_checkbox.dart';
import 'package:provider/provider.dart';
import 'package:transito/models/favourite.dart';
import 'package:transito/providers/favourites_service.dart';
import 'package:transito/screens/navbar_screens/main_screen.dart';

import '../models/app_colors.dart';
import '../models/arrival_info.dart';

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
  late Future<Map<String?, List<String?>>> favouriteServicesList;

  // function to display snackbar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // function to properly sort the bus arrival info according to the Bus Service number
  BusArrivalInfo sortBusArrivalInfo(BusArrivalInfo value) {
    var _value = value;
    _value.services.sort((a, b) => compareNatural(a.serviceNum, b.serviceNum));

    return _value;
  }

  @override
  void initState() {
    super.initState();
    // sorts bus services list according to the Bus Service number correctly
    widget.busServicesList.sort((a, b) => compareNatural(a, b));
    favouriteServicesList = FavouritesService()
        .getFavouriteServicesByBusStopCode(context.read<User?>()!.uid, widget.busStopCode);
  }

  @override
  Widget build(BuildContext context) {
    String? userId = context.read<User?>()?.uid;

    Future<void> updateFavorites() async {
      // debugPrint('isParentSelected: ${ParentChildCheckbox.isParentSelected}');
      debugPrint('selectedChildren ${ParentChildCheckbox.selectedChildrens}');

      List<String?> selectedServices = ParentChildCheckbox.selectedChildrens['Bus Services']!;

      // check if user wants to edit or remove favourites
      if (selectedServices.isNotEmpty) {
        // if services were selected then update the favourites list
        FavouritesService().updateFavourite(
          Favourite(
              busStopCode: widget.busStopCode,
              busStopName: widget.busStopName,
              busStopAddress: widget.busStopAddress,
              busStopLocation: widget.busStopLocation,
              services: selectedServices),
          userId!,
        );
        _showSnackBar('Updated favourites for ${widget.busStopName}');
        // debugPrint("$favouriteServicesList");
        // navigate to main screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const MainScreen(),
          ),
          (Route<dynamic> route) => false,
        );
      } else {
        // retrieve the list of services that the user initially had in their favourites
        List<String?> initialServices = await favouriteServicesList.then((value) {
          return value['Bus Services']!;
        });

        // if no services were selected then remove the bus stop from favourites list
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text("Delete Favourite"),
                  content: const Text(
                      "Are you sure you want to remove this bus stop from your favourites?"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("No"),
                    ),
                    TextButton(
                      onPressed: () {
                        // delete favourite
                        FavouritesService().removeFavourite(
                            Favourite(
                                busStopCode: widget.busStopCode,
                                busStopName: widget.busStopName,
                                busStopAddress: widget.busStopAddress,
                                busStopLocation: widget.busStopLocation,
                                services: initialServices),
                            userId!);
                        _showSnackBar('Removed ${widget.busStopName} from favourites');
                        // navigate to main screen
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MainScreen(),
                          ),
                          (Route<dynamic> route) => false,
                        );
                      },
                      child: const Text("Yes"),
                    ),
                  ],
                ));
      }
      // navigate back to main screen
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
            FutureBuilder(
              future: favouriteServicesList,
              builder: (context, AsyncSnapshot<Map<String?, List<String?>>> snapshot) {
                if (snapshot.hasData) {
                  return Expanded(
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
                            initialChildrenValue: snapshot.data,
                            parentCheckboxColor: AppColors.accentColour,
                            childrenCheckboxColor: AppColors.accentColour,
                            parentCheckboxScale: 1.35,
                            childrenCheckboxScale: 1.35,
                            gap: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                      onPressed: () => updateFavorites(), child: const Text("Save changes")),
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
