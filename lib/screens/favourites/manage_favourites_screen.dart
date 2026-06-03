import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/services/favourites_service.dart';
import 'package:transito/models/favourites/favourite.dart';
import 'package:transito/widgets/common/adaptive_floating_action_button.dart';
import 'package:transito/widgets/favourites/favourite_name_card.dart';

import 'edit_favourite_screen.dart';

class ManageFavouritesScreen extends StatefulWidget {
  const ManageFavouritesScreen({super.key});

  @override
  State<ManageFavouritesScreen> createState() => _ManageFavouritesScreenState();
}

class _ManageFavouritesScreenState extends State<ManageFavouritesScreen> {
  bool isFabVisible = true;
  late Future<List<Favourite>> _futureFavouritesList;
  List<Favourite> reorderedFavouritesList = [];

  // function to route to edit favourites screen
  Future<void> goToEditFavouritesScreen(BuildContext context, Favourite favourite) async {
    // debugPrint('$busServicesList');
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditFavouritesScreen(
          busStopCode: favourite.busStopCode,
          busStopName: favourite.busStopName,
          busStopAddress: favourite.busStopAddress,
          busStopLocation: favourite.busStopLocation,
          sources: favourite.sources,
        ),
        settings: const RouteSettings(name: 'EditFavouritesScreen'),
      ),
    );
  }

  // function to hide the fab when the user is scrolling down the list to avoid blocking content
  bool hideFabOnScroll(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.forward) {
      !isFabVisible ? setState(() => isFabVisible = true) : null;
    } else if (notification.direction == ScrollDirection.reverse) {
      isFabVisible ? setState(() => isFabVisible = false) : null;
    }

    return true;
  }

  @override
  void initState() {
    super.initState();
    _futureFavouritesList = FavouritesService().getFavourites(context.read<User?>()!.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Favourites'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Drag and drop to reorder your favourites",
                    style: TextStyle(
                        fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Click the pencil icon to modify or delete your favourites",
                    style: TextStyle(
                        fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
            FutureBuilder<List<Favourite>>(
              future: _futureFavouritesList,
              builder: (context, AsyncSnapshot<List<Favourite>> snapshot) {
                if (snapshot.hasData) {
                  List<Favourite> favouritesList = snapshot.data!;
                  return Expanded(
                    child: NotificationListener<UserScrollNotification>(
                      onNotification: (notification) => hideFabOnScroll(notification),
                      child: ReorderableListView.builder(
                          itemBuilder: (context, index) {
                            return Padding(
                              key: Key(favouritesList[index].busStopCode),
                              padding: const EdgeInsets.only(bottom: 18),
                              child: FavouriteNameCard(
                                  busStopName: favouritesList[index].busStopName,
                                  onTap: () =>
                                      goToEditFavouritesScreen(context, favouritesList[index])),
                            );
                          },
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shrinkWrap: true,
                          buildDefaultDragHandles: true,
                          itemCount: favouritesList.length,
                          // calls reorder function in FavouritesProvider to reorder the favourites list
                          onReorder: (oldIndex, newIndex) {
                            if (oldIndex < newIndex) {
                              // removing the item at oldIndex will shorten the list by 1
                              newIndex--;
                            }
                            favouritesList.insert(newIndex, favouritesList.removeAt(oldIndex));

                            setState(() {
                              reorderedFavouritesList = favouritesList;
                            });
                          }),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                } else {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 3));
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: isFabVisible
          ? AdaptiveFloatingActionButton(
              onPressed: () => FavouritesService()
                  .reorderFavourites(reorderedFavouritesList, context.read<User?>()!.uid)
                  .then(
                    (value) => Navigator.pop(context),
                  ),
              materialSymbol: Symbols.done_rounded,
              cupertinoSymbolString: 'checkmark',
            )
          : null,
    );
  }
}
