import 'package:flutter/material.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({Key? key}) : super(key: key);

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favourites'),
      ),
      body: const Center(
        child: Text("This is the favourites screen"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => debugPrint('bruh'),
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }
}
