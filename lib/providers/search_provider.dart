import 'package:flutter/material.dart';

import '../models/bus_stops.dart';

class SearchProvider extends ChangeNotifier {
  List<dynamic> _recentSearches = [];

  List<dynamic> get recentSearches => _recentSearches;

  void addRecentSearch(dynamic search) {
    if (_recentSearches.every((element) => element.runtimeType == BusStopInfo
        ? element.busStopCode != search.busStopCode
        : element.serviceNo != search.serviceNo)) {
      _recentSearches.add(search);
    } else {
      debugPrint("Already added in recent");
    }
    notifyListeners();
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    notifyListeners();
  }
}
