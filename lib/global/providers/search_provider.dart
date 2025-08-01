import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transito/models/api/transito/bus_services.dart';
import 'package:transito/models/api/transito/bus_stops.dart';
import 'package:transito/models/api/transito/onemap/onemap_search.dart';

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

    // checks if the type of the recent search to be added is a bus service or bus stop
    if (search.runtimeType == BusStop) {
      // if the recent search is a bus stop, then the list is filtered to only include bus stops
      List<BusStop> busStopRecents = _recentSearches.whereType<BusStop>().toList();

      if (busStopRecents.every((element) => element.code != search.code)) {
        _recentSearches.insert(0, search);
        debugPrint('Added recent search: ${search.name}');
      } else {
        _recentSearches.removeWhere((element) => element is BusStop && element.code == search.code);
        _recentSearches.insert(0, search);
        debugPrint('Moved recent search to top: ${search.name}');
      }
    } else if (search.runtimeType == BusService) {
      // if the recent search is a bus service, then the list is filtered to only include bus services
      List<BusService> busServiceRecents = _recentSearches.whereType<BusService>().toList();

      if (busServiceRecents.every((element) => element.serviceNo != search.serviceNo)) {
        _recentSearches.insert(0, search);
        debugPrint('Added recent search: ${search.serviceNo}');
      } else {
        _recentSearches.removeWhere(
            (element) => element is BusService && element.serviceNo == search.serviceNo);
        _recentSearches.insert(0, search);
        debugPrint('Moved recent search to top: ${search.serviceNo}');
      }
    } else if (search.runtimeType == OneMapSearchData) {
      // if the recent search is a OneMapSearchData, then the list is filtered to only include OneMapSearchData
      List<OneMapSearchData> oneMapRecents = _recentSearches.whereType<OneMapSearchData>().toList();

      if (oneMapRecents.every((element) => element.name != search.name)) {
        _recentSearches.insert(0, search);
        debugPrint('Added recent search: ${search.name}');
      } else {
        _recentSearches
            .removeWhere((element) => element is OneMapSearchData && element.name == search.name);
        _recentSearches.insert(0, search);
        debugPrint('Moved recent search to top: ${search.name}');
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
