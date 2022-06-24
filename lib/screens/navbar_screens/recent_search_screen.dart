import 'package:flutter/material.dart';
import 'package:transito/widgets/recent_search_list.dart';

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
        IconButton(
          icon: const Hero(tag: 'SearchIcon', child: Icon(Icons.search)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchScreen(),
              ),
            );
          },
        ),
      ]),
      body: RecentSearchList(),
    );
  }
}
