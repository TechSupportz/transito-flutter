import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:transito/providers/favourites_provider.dart';
import 'package:transito/widgets/favourites_timing_card.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({Key? key}) : super(key: key);

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  bool isFabVisible = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<FavouritesProvider>(
      builder: (context, value, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Favourites'),
          ),
          body: ListView.separated(
            itemBuilder: (context, int index) {
              return FavouritesTimingCard(
                busStopCode: value.favouritesList[index].busStopCode,
                busStopName: value.favouritesList[index].busStopName,
                busStopLocation: LatLng(
                    value.favouritesList[index].latitude, value.favouritesList[index].longitude),
                services: value.favouritesList[index].services,
              );
            },
            padding: const EdgeInsets.only(top: 12, bottom: 32),
            separatorBuilder: (BuildContext context, int index) => const SizedBox(
              height: 18,
            ),
            itemCount: value.favouritesList.length,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => debugPrint('bruh'),
            child: const Icon(Icons.edit_rounded),
          ),
        );
      },
    );
  }
}
