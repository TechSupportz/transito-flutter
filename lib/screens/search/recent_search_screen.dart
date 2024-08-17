import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/search_provider.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/widgets/search/recent_search_list.dart';

import 'search_screen.dart';

class RecentSearchScreen extends StatefulWidget {
  const RecentSearchScreen({super.key});

  @override
  State<RecentSearchScreen> createState() => _RecentSearchScreenState();
}

class _RecentSearchScreenState extends State<RecentSearchScreen> {
  TextEditingController textFieldController = TextEditingController();

  showClearAlertDialog(BuildContext context) => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clear recent searches?'),
          content: const Text(
              'Are you sure you want to clear your recent searches? \n\nThis action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Provider.of<SearchProvider>(context, listen: false).clearAllRecentSearches();
                Navigator.pop(context);
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(AppColors.sortaRed),
              ),
              child: const Text('Clear'),
            )
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recent Searches'), actions: [
        // button to open the search interface
        IconButton(
          icon: const Icon(Icons.delete_rounded),
          onPressed: () => showClearAlertDialog(context),
        ),
      ]),
      // displays the recent search list widget
      body: const RecentSearchList(),
      // floating action button to clear the recent searches list by calling a function in the search provider
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SearchScreen(),
              settings: const RouteSettings(name: 'SearchScreen'),
            ),
          );
          HapticFeedback.selectionClick();
        },
        heroTag: 'searchIcon',
        child: const Icon(Icons.search_rounded),
      ),
    );
  }
}
