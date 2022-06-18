import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transito/providers/favourites_provider.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({Key? key}) : super(key: key);

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

//TODO: Create widget to display favourites
class _FavouritesScreenState extends State<FavouritesScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<FavouritesProvider>(
      builder: (context, value, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Favourites'),
          ),
          body: Center(
            child: Text(value.favouritesList.toString()),
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
