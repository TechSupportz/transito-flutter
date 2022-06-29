import 'package:flutter/material.dart';

import '../models/favourite.dart';

class FavouritesProvider extends ChangeNotifier {
  List<Favourite> _favouritesList = [];

  List<Favourite> get favouritesList => _favouritesList;

  void addFavourite(Favourite favourite) {
    _favouritesList.add(favourite);
    notifyListeners();
  }

  // removes the favourite from the list based on bus stop code
  void removeFavourite(String busStopCode) {
    _favouritesList.removeWhere((element) => element.busStopCode == busStopCode);
    notifyListeners();
  }

  // finds index where the old favourite is located based on bus stop code and replaces the old favourite with the new favourite
  void updateFavourite(Favourite favourite) {
    _favouritesList[_favouritesList
        .indexWhere((element) => element.busStopCode == favourite.busStopCode)] = favourite;
    notifyListeners();
  }

  void reorderFavourite(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      // removing the item at oldIndex will shorten the list by 1
      newIndex--;
    }
    _favouritesList.insert(newIndex, _favouritesList.removeAt(oldIndex));
    notifyListeners();
  }
}
