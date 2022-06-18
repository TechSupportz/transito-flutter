import 'package:flutter/material.dart';
import '../models/favourite.dart';

class FavouritesProvider extends ChangeNotifier {
  List<Favourite> _favouritesList = [];

  List<Favourite> get favouritesList => _favouritesList;

  void addFavourite(Favourite favourite) {
    _favouritesList.add(favourite);
    notifyListeners();
  }

  void removeFavourite(Favourite favourite) {
    _favouritesList.remove(favourite);
    notifyListeners();
  }
}
