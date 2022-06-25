import 'package:flutter/material.dart';

import '../models/bus_services.dart';
import '../models/bus_stops.dart';

class SearchProvider extends ChangeNotifier {
  // stores both the bus services and bus stops hence its a dynamic list
  final List<dynamic> _recentSearches = [];

  List<dynamic> get recentSearches => _recentSearches;

  void addRecentSearch(dynamic search) {
    // checks if the the type of the recent search to be added is a bus service or bus stop
    if (search.runtimeType == BusStopInfo) {
      // if the recent search is a bus stop, then the list is filtered to only include bus stops
      List _busStopRecents =
          _recentSearches.where((element) => element.runtimeType == BusStopInfo).toList();
      // checks if the bus stop is already in the list
      if (_busStopRecents.every((element) => element.busStopCode != search.busStopCode)) {
        _recentSearches.add(search);
        debugPrint('Added recent search: ${search.busStopName}');
      } else {
        debugPrint("Already added in recent");
      }
    } else if (search.runtimeType == BusServiceInfo) {
      // if the recent search is a bus service, then the list is filtered to only include bus services
      List _busServiceRecents =
          _recentSearches.where((element) => element.runtimeType == BusServiceInfo).toList();
      // checks if the bus service is already in the list
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
