import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_skeleton_ui/flutter_skeleton_ui.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:parent_child_checkbox/parent_child_checkbox.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/services/favourites_service.dart';
import 'package:transito/models/api/lta/arrival_info.dart';
import 'package:transito/models/api/transito/bus_services.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/models/favourites/favourite.dart';
import 'package:transito/models/secret.dart';
import 'package:transito/screens/navigator_screen.dart';
import 'package:transito/widgets/common/chekbox_skeleton.dart';

class EditFavouritesScreen extends StatefulWidget {
  const EditFavouritesScreen({
    super.key,
    required this.busStopCode,
    required this.busStopName,
    required this.busStopAddress,
    required this.busStopLocation,
    this.busServicesList,
  });
  final String busStopCode;
  final String busStopName;
  final String busStopAddress;
  final LatLng busStopLocation;
  final List<String>? busServicesList;

  @override
  State<EditFavouritesScreen> createState() => _EditFavouritesScreenState();
}

const checkBoxFontStyle = TextStyle(
  fontSize: 24,
);

class _EditFavouritesScreenState extends State<EditFavouritesScreen> {
  late Future<Map<String?, List<String?>>> futureFavouriteServicesList;
  late Future<List<String>> futureBusServicesList;

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

  // function to fetch the list of services available at the bus stop
  // if the services are already available in the props, then it will return the services from the props
  Future<List<String>> fetchServicesList() async {
    if (widget.busServicesList != null) {
      debugPrint("Retrieving services from props");
      return widget.busServicesList!;
    }

    debugPrint("Fetching all services");

    final response = await http.get(
      Uri.parse('${Secret.API_URL}/bus-stop/${widget.busStopCode}/services'),
    );

    if (response.statusCode == 200) {
      debugPrint("Services fetched");
      return BusStopServicesApiResponse.fromJson(json.decode(response.body)).data;
    } else {
      debugPrint("Error fetching bus stop services");
      throw Exception("Error fetching bus stop services");
    }
  }

  @override
  void initState() {
    super.initState();
    futureBusServicesList = fetchServicesList();
    futureFavouriteServicesList = FavouritesService()
        .getFavouriteServicesByBusStopCode(context.read<User?>()!.uid, widget.busStopCode);
  }

  @override
  Widget build(BuildContext context) {
    String? userId = context.read<User?>()?.uid;

    Future<void> deleteFavorites() async {
      // retrieve the list of services that the user initially had in their favourites
      List<String?> initialServices = await futureFavouriteServicesList.then((value) {
        return value['Bus Services']!;
      });

      // if no services were selected then remove the bus stop from favourites list
      if (context.mounted) {
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
                            builder: (context) => const NavigatorScreen(),
                          ),
                          (Route<dynamic> route) => false,
                        );
                      },
                      child: const Text("Yes"),
                    ),
                  ],
                ));
      }
    }

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
            builder: (context) => const NavigatorScreen(),
          ),
          (Route<dynamic> route) => false,
        );
      } else {
        await deleteFavorites();
      }
      // navigate back to main screen
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Favourites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            onPressed: () {
              deleteFavorites();
            },
          )
        ],
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
                            color: AppColors.accentColour, borderRadius: BorderRadius.circular(8)),
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
                  height: 8,
                ),
              ],
            ),
            FutureBuilder(
              future: Future.wait([futureFavouriteServicesList, futureBusServicesList]),
              builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                Widget servicesChecklist = Expanded(child: const SizedBox());

                if (snapshot.hasData) {
                  var initialChildrenValue = snapshot.data![0] as Map<String?, List<String?>>;
                  var busServicesList = snapshot.data![1] as List<String>;

                  // this filters out services which have stopped operating but are still in the user's favourites
                  if (initialChildrenValue["Bus Services"] != null &&
                      !initialChildrenValue["Bus Services"]!.every(
                        (service) => busServicesList.contains(service),
                      )) {
                    initialChildrenValue["Bus Services"] = initialChildrenValue["Bus Services"]!
                        .where(
                          (service) => busServicesList.contains(service),
                        )
                        .toList();
                  }

                  servicesChecklist = ShaderMask(
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
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 8, bottom: 16),
                        child: Column(
                          children: [
                            ParentChildCheckbox(
                              parent: const Text("Bus Services", style: checkBoxFontStyle),
                              // initialParentValue: {'Bus Services': true},
                              initialChildrenValue: initialChildrenValue,
                              parentCheckboxColor: AppColors.accentColour,
                              childrenCheckboxColor: AppColors.accentColour,
                              parentCheckboxScale: 1.35,
                              childrenCheckboxScale: 1.35,
                              gap: 2,
                              children: [
                                for (var service in busServicesList)
                                  Text(service, style: checkBoxFontStyle),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Expanded(
                  child: Skeleton(
                    isLoading:
                        snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData,
                    skeleton: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          CheckboxSkeleton(),
                          SizedBox(
                            height: 2,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 15),
                              child: SkeletonListView(
                                spacing: 10,
                                item: CheckboxSkeleton(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    child: servicesChecklist,
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                      onPressed: () => updateFavorites(), child: const Text("Save changes")),
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
