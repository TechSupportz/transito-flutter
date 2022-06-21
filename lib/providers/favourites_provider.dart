import 'package:flutter/material.dart';
import '../models/favourite.dart';

class FavouritesProvider extends ChangeNotifier {
  List<Favourite> _favouritesList = [];

  List<Favourite> get favouritesList => _favouritesList;

  void addFavourite(Favourite favourite) {
    _favouritesList.add(favourite);
    notifyListeners();
  }

  void removeFavourite(String busStopCode) {
    _favouritesList.removeWhere((element) => element.busStopCode == busStopCode);
    notifyListeners();
  }

  void updateFavourite(Favourite favourite) {
    _favouritesList[_favouritesList
        .indexWhere((element) => element.busStopCode == favourite.busStopCode)] = favourite;
    notifyListeners();
  }

  void reorderFavourite(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex--;
    }
    _favouritesList.insert(newIndex, _favouritesList.removeAt(oldIndex));
    notifyListeners();
  }
}
