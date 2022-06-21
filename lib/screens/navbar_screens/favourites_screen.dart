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

  bool hideFabOnScroll(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.forward) {
      !isFabVisible ? setState(() => isFabVisible = true) : null;
    } else if (notification.direction == ScrollDirection.reverse) {
      isFabVisible ? setState(() => isFabVisible = false) : null;
    }

    return true;
  }

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
          body: value.favouritesList.isNotEmpty
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
          floatingActionButton: isFabVisible
              ? FloatingActionButton(
                  onPressed: () => goToManageFavouritesScreen(context),
                  child: const Icon(Icons.edit_rounded),
                )
              : null,
        );
      },
    );
  }
}
