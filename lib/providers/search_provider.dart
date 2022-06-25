import 'package:flutter/material.dart';

import '../models/bus_services.dart';
import '../models/bus_stops.dart';

class SearchProvider extends ChangeNotifier {
  final List<dynamic> _recentSearches = [];

  List<dynamic> get recentSearches => _recentSearches;

  void addRecentSearch(
    dynamic search,
  ) {
    debugPrint("${search.runtimeType}");

    if (search.runtimeType == BusStopInfo) {
      List _busStopRecents =
          _recentSearches.where((element) => element.runtimeType == BusStopInfo).toList();
      if (_busStopRecents.every((element) => element.busStopCode != search.busStopCode)) {
        _recentSearches.add(search);
        debugPrint('Added recent search: ${search.busStopName}');
      } else {
        debugPrint("Already added in recent");
      }
    } else if (search.runtimeType == BusServiceInfo) {
      List _busServiceRecents =
          _recentSearches.where((element) => element.runtimeType == BusServiceInfo).toList();
      if (_busServiceRecents.every((element) => element.serviceNo != search.serviceNo)) {
        _recentSearches.add(search);
        debugPrint('Added recent search: ${search.serviceNo}');
      } else {
        debugPrint("Already added in recent");
      }
    } else {
      debugPrint("Already added in recent");
    }
    notifyListeners();
  }

  void clearAllRecentSearches() {
    _recentSearches.clear();
    debugPrint("Cleared all recent searches");
    notifyListeners();
  }
}
