import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:transito/providers/search_provider.dart';
import 'package:transito/widgets/search/recent_search_list.dart';

import 'search_screen.dart';

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
        IconButton(
          icon: const Icon(Icons.delete_rounded),
          onPressed: () {
            Provider.of<SearchProvider>(context, listen: false).clearAllRecentSearches();
          },
        ),
      ]),
      // displays the recent search list widget
      body: const RecentSearchList(),
      // floating action button to clear the recent searches list by calling a function in the search provider
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // FIXME - this is a temp fix to the issue of the search screen not being able to be opened from the recent search screen
          // 
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => const SearchScreen(),
          //   ),
          // );
          HapticFeedback.selectionClick();
        },
        heroTag: 'searchIcon',
        child: const Icon(Icons.search_rounded),
      ),
    );
  }
}
