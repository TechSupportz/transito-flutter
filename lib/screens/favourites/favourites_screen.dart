import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/services/favourites_service.dart';
import 'package:transito/models/favourites/favourite.dart';
import 'package:transito/screens/favourites/manage_favourites_screen.dart';
import 'package:transito/widgets/favourites/favourites_timing_card.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

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
          settings: const RouteSettings(name: 'ManageFavouritesScreen')),
    );
  }

  // @override
  // void initState() {
  //   super.initState();
  //   FavouritesService().streamFavourites(context.read<User?>()!.uid).listen((value) {
  //     print(value[0].busStopName);
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    String userId = context.watch<User>().uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favourites'),
      ),
      // if the user has favourites display them via the favourites_timing_card widget, otherwise display a message
      body: StreamBuilder<List<Favourite>>(
          stream: FavouritesService().streamFavourites(userId),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<Favourite> favouritesList = snapshot.data!;

              return favouritesList.isNotEmpty
                  // notification listener to hide or show the FAB depending if the user is scrolling or not
                  ? NotificationListener<UserScrollNotification>(
                      onNotification: (notification) => hideFabOnScroll(notification),
                      child: ListView.separated(
                        itemBuilder: (context, int index) {
                          return FavouritesTimingCard(
                            code: favouritesList[index].busStopCode,
                            name: favouritesList[index].busStopName,
                            address: favouritesList[index].busStopAddress,
                            busStopLocation: favouritesList[index].busStopLocation,
                            services: favouritesList[index].services,
                          );
                        },
                        padding: const EdgeInsets.only(top: 12, bottom: 32, left: 12, right: 12),
                        separatorBuilder: (BuildContext context, int index) => const SizedBox(
                          height: 16,
                        ),
                        itemCount: favouritesList.length,
                        cacheExtent: favouritesList.length.toDouble() * 250,
                      ),
                    )
                  // if the user has no favourites display a message
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
                            ),
                          ),
                        ],
                      ),
                    );
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 3),
              );
            }
          }),
      // floating action button to open the manage favourites screen
      floatingActionButton: isFabVisible
          ? FloatingActionButton(
              heroTag: 'favouritesFAB',
              onPressed: () => goToManageFavouritesScreen(context),
              child: const Icon(Icons.edit_rounded),
            )
          : null,
    );
  }
}
