import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transito/providers/search_provider.dart';
import 'package:transito/widgets/bus_service_card.dart';

import '../models/bus_stops.dart';
import 'bus_stop_card.dart';

class RecentSearchList extends StatelessWidget {
  const RecentSearchList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, value, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: value.recentSearches.isEmpty ? _noRecentSearches() : _recentSearches(value),
        );
      },
    );
  }

  ListView _recentSearches(SearchProvider value) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 16.0, bottom: 32.0, left: 12.0, right: 12.0),
      itemCount: value.recentSearches.length,
      itemBuilder: (context, index) {
        if (value.recentSearches[index].runtimeType == BusStopInfo) {
          return BusStopCard(busStopInfo: value.recentSearches[index], searchMode: true);
        } else {
          return BusServiceCard(busServiceInfo: value.recentSearches[index]);
        }
      },
      separatorBuilder: (context, index) => const SizedBox(height: 16),
    );
  }

  Center _noRecentSearches() {
    return const Center(
      child: Text(
        "No recent searches",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}
