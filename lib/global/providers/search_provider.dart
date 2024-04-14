import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transito/models/api/transito/bus_services.dart';
import 'package:transito/models/api/transito/bus_stops.dart';

class SearchProvider extends ChangeNotifier {
  // stores both the bus services and bus stops hence its a dynamic list
  List<dynamic> _recentSearches = [];

  SharedPreferences? prefs;

  SearchProvider() {
    initState();
  }

  List<dynamic> get recentSearches => _recentSearches;

  void initState() async {
    prefs ??= await SharedPreferences.getInstance();
    var localRecentSearches = prefs?.getStringList('recentSearchesList');

    if (localRecentSearches != null) {
      debugPrint('Retrieving search shared preferences');
      _recentSearches = localRecentSearches.map((e) {
        var json = jsonDecode(e);

        if (json['serviceNo'] != null) {
          return BusService.fromJson(json);
        } else {
          return BusStop.fromJson(json);
        }
      }).toList();
    }

    notifyListeners();
  }

  void updateSharedPref() {
    var localRecentSearches = _recentSearches.map((e) {
      return jsonEncode(e);
    }).toList();

    prefs?.setStringList('recentSearchesList', localRecentSearches);
    debugPrint('Updated search shared preferences');
  }

  void clearSharedPref() {
    prefs?.remove('recentSearchesList');
    debugPrint('Cleared search shared preferences');
  }

  void addRecentSearch(dynamic search) {
    if (_recentSearches.length >= 10) {
      _recentSearches.removeAt(0);
    }

    // checks if the the type of the recent search to be added is a bus service or bus stop
    if (search.runtimeType == BusStop) {
      // if the recent search is a bus stop, then the list is filtered to only include bus stops
      List<BusStop> busStopRecents = _recentSearches.whereType<BusStop>().toList();
      // checks if the bus stop is already in the list
      if (busStopRecents.every((element) => element.code != search.code)) {
        _recentSearches.add(search);
        debugPrint('Added recent search: ${search.name}');
      } else {
        busStopRecents.indexWhere((element) => element.code == search.code);
        debugPrint("Already added in recent");
      }
    } else if (search.runtimeType == BusService) {
      // if the recent search is a bus service, then the list is filtered to only include bus services
      List<BusService> busServiceRecents = _recentSearches.whereType<BusService>().toList();
      // checks if the bus service is already in the list
      if (busServiceRecents.every((element) => element.serviceNo != search.serviceNo)) {
        _recentSearches.add(search);
        debugPrint('Added recent search: ${search.serviceNo}');
      } else {
        debugPrint("Already added in recent");
      }
    } else {
      debugPrint("Already added in recent");
    }
    notifyListeners();
    updateSharedPref();
  }

  void clearAllRecentSearches() {
    _recentSearches.clear();
    debugPrint("Cleared all recent searches");

    notifyListeners();
    clearSharedPref();
  }
}
