import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transito/providers/search_provider.dart';

import 'bus_stop_card.dart';

class RecentSearchList extends StatelessWidget {
  const RecentSearchList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, value, child) {
        if (value.recentSearches.isEmpty) {
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
        } else {
          return ListView.separated(
            itemBuilder: (context, index) {
              return BusStopCard(busStopInfo: value.recentSearches[index]);
            },
            separatorBuilder: (context, index) => SizedBox(height: 16),
            itemCount: value.recentSearches.length,
          );
        }
      },
    );
  }
}
