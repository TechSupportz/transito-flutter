import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:transito/providers/favourites_provider.dart';
import 'package:transito/screens/manage_favourites_screen.dart';
import 'package:transito/widgets/favourites_timing_card.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({Key? key}) : super(key: key);

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  bool isFabVisible = true;

  // sets the state of the FAB to hide or show depending if the user is scrolling in order to prevent blocking content
  bool hideFabOnScroll(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.forward) {
      !isFabVisible ? setState(() => isFabVisible = true) : null;
    } else if (notification.direction == ScrollDirection.reverse) {
      isFabVisible ? setState(() => isFabVisible = false) : null;
    }
    return true;
  }

  // function to open the manage favourites screen
  void goToManageFavouritesScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ManageFavouritesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavouritesProvider>(
      builder: (context, value, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Favourites'),
          ),
          // if the user has favourites display them via the favourites_timing_card widget, otherwise display a message
          body: value.favouritesList.isNotEmpty
              // notification listener to hide or show the FAB depending if the user is scrolling or not
              ? NotificationListener<UserScrollNotification>(
                  onNotification: (notification) => hideFabOnScroll(notification),
                  child: ListView.separated(
                    itemBuilder: (context, int index) {
                      return FavouritesTimingCard(
                        busStopCode: value.favouritesList[index].busStopCode,
                        busStopName: value.favouritesList[index].busStopName,
                        busStopAddress: value.favouritesList[index].busStopAddress,
                        busStopLocation: LatLng(value.favouritesList[index].latitude,
                            value.favouritesList[index].longitude),
                        services: value.favouritesList[index].services,
                      );
                    },
                    padding: const EdgeInsets.only(top: 12, bottom: 32, left: 12, right: 12),
                    separatorBuilder: (BuildContext context, int index) => const SizedBox(
                      height: 18,
                    ),
                    itemCount: value.favouritesList.length,
                  ),
                )
              // if the user has no favourites display a message
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "This place is real empty",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "Try adding some favourites!",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
          // floating action button to open the manage favourites screen
          floatingActionButton: isFabVisible
              ? FloatingActionButton(
                  heroTag: 'favouritesFAB',
                  onPressed: () => goToManageFavouritesScreen(context),
                  child: const Icon(Icons.edit_rounded),
                )
              : null,
        );
      },
    );
  }
}
