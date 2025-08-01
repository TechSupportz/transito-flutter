import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_skeleton_ui/flutter_skeleton_ui.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:transito/global/providers/search_provider.dart';
import 'package:transito/models/api/transito/onemap/onemap_search.dart';
import 'package:transito/models/secret.dart';
import 'package:transito/widgets/search/recent_search_list.dart';
import 'package:transito/widgets/search/search_result_card.dart';

class SearchDialog extends StatefulWidget {
  const SearchDialog({super.key, required this.onSearchSelected});

  final ValueSetter<OneMapSearchData> onSearchSelected;

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  late Future<OneMapSearch> _searchResults;

  Timer? _debounce;
  final _textFieldController = TextEditingController();
  late final FocusNode _searchFocusNode = FocusNode();

  Future<OneMapSearch> getSearchResults(String query, int page) async {
    if (query.isEmpty) {
      return Future.value(OneMapSearch(totalCount: 0, count: 0, totalPages: 0, page: 1, data: []));
    }

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
    final searchProvider = Provider.of<SearchProvider>(context);

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
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
            if (snapshot.hasData) {
              OneMapSearch res = snapshot.data!;

              // This should probably be ur recent searches widget
              if (res.count == 0 && _textFieldController.text.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 12.0, top: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Recent searches",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: searchProvider.recentSearches.isEmpty
                                ? null
                                : () => searchProvider.clearAllRecentSearches(),
                            child: Text(
                              "Clear all",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const RecentSearchList(),
                  ],
                );
              }

              if (res.count == 0 && snapshot.connectionState == ConnectionState.done) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "We can't find that place 🤔",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Try checking for typos or searching for a landmark or address nearby instead.",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return Skeleton(
                isLoading: snapshot.connectionState == ConnectionState.waiting,
                skeleton: SkeletonListView(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 32.0, left: 12.0, right: 12.0),
                  itemBuilder: (context, _) => SkeletonLine(
                    style: SkeletonLineStyle(
                      height: 88,
                      borderRadius: BorderRadius.circular(12),
                      padding: const EdgeInsets.only(bottom: 16),
                    ),
                  ),
                ),
                child: ListView.separated(
                  itemCount: res.count,
                  padding: const EdgeInsets.only(top: 16.0, bottom: 32.0, left: 12.0, right: 12.0),
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final result = res.data[index];
                    return SearchResultCard(
                      searchData: result,
                      onTap: () {
                        widget.onSearchSelected(result);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              );
            } else if (snapshot.hasError) {
              debugPrint("<=== ERROR ${snapshot.error} ===>");
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "⚠️ Something went wrong",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Please try again later",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return const Center(child: CircularProgressIndicator(strokeWidth: 3));
          },
        ),
      ),
    );
  }
}
