import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:transito/widgets/recent_search_list.dart';

import '../../providers/search_provider.dart';
import '../search_screen.dart';

class RecentSearchScreen extends StatefulWidget {
  const RecentSearchScreen({Key? key}) : super(key: key);

  @override
  State<RecentSearchScreen> createState() => _RecentSearchScreenState();
}

class _RecentSearchScreenState extends State<RecentSearchScreen> {
  TextEditingController textFieldController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recent Searches'), actions: [
        // button to open the search interface
        Hero(
          tag: 'searchPostfix',
          child: IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(),
                ),
              );
            },
          ),
        ),
      ]),
      // displays the recent search list widget
      body: RecentSearchList(),
      // floating action button to clear the recent searches list by calling a function in the search provider
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Provider.of<SearchProvider>(context, listen: false).clearAllRecentSearches();
          HapticFeedback.selectionClick();
        },
        heroTag: 'recentSearchFAB',
        child: const Icon(Icons.delete_rounded),
      ),
    );
  }
}
