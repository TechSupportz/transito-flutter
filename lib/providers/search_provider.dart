import 'package:flutter/material.dart';

class SearchProvider extends ChangeNotifier {
  List<dynamic> _recentSearches = [];

  List<dynamic> get recentSearches => _recentSearches;

  void addRecentSearch(dynamic search) {
    _recentSearches.add(search);
    notifyListeners();
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    notifyListeners();
  }
}
