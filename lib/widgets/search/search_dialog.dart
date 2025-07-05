import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:transito/models/api/transito/onemap/onemap_search.dart';
import 'package:transito/models/secret.dart';

class SearchDialog extends StatefulWidget {
  const SearchDialog({super.key});

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  late Future<OneMapSearch> _searchResults;

  Timer? _debounce;
  final _textFieldController = TextEditingController();
  late final FocusNode _searchFocusNode = FocusNode();

  Future<OneMapSearch> getSearchResults(String query, int page) async {
    final response =
        await http.get(Uri.parse('${Secret.API_URL}/onemap/search?query=$query&page=$page'));

    if (response.statusCode == 200) {
      // debugPrint('Search results: ${response.body}'); //NOTE - remove output in production
      return OneMapSearch.fromJson(json.decode(response.body));
    } else {
      debugPrint(
          'Failed to load search results: ${response.statusCode}'); //NOTE - remove output in production
      throw Exception('Failed to load search results');
    }
  }

  // debounces the search query to prevent spamming the api
  void _onSearchChanged(String query, int page) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: query.length < 3 ? 0 : 200), () {
      setState(() {
        _searchResults = getSearchResults(query, page);
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _searchResults = Future.value(OneMapSearch(
      totalCount: 0,
      count: 0,
      totalPages: 0,
      page: 1,
      data: [],
    ));
  }

  @override
  void dispose() {
    _textFieldController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _textFieldController,
            focusNode: _searchFocusNode,
            autofocus: true,
            onChanged: (_) => _onSearchChanged(_textFieldController.text, 1),
            decoration: InputDecoration(
              hintText: 'Search...',
              isDense: false,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
        body: FutureBuilder<OneMapSearch>(
          future: _searchResults,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
              return const Center(child: Text('No results found.'));
            } else {
              final results = snapshot.data!.data;
              return ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final result = results[index];
                  return ListTile(
                    title: Text(result.name),
                    subtitle: Text(result.address),
                    onTap: () {
                      // Handle the tap on the result
                    },
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
