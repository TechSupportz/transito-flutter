import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_skeleton_ui/flutter_skeleton_ui.dart';
import 'package:http/http.dart' as http;
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/search_provider.dart';
import 'package:transito/models/api/transito/bus_services.dart';
import 'package:transito/models/api/transito/bus_stops.dart';
import 'package:transito/models/api/transito/onemap/onemap_search.dart';
import 'package:transito/models/enums/search_mode_enum.dart';
import 'package:transito/models/secret.dart';
import 'package:transito/widgets/bus_info/bus_service_card.dart';
import 'package:transito/widgets/bus_info/bus_stop_card.dart';
import 'package:transito/widgets/common/app_symbol.dart';
import 'package:transito/widgets/common/error_text.dart';
import 'package:transito/widgets/search/recent_search_list.dart';
import 'package:transito/widgets/search/search_result_card.dart';

class SearchDialog extends StatefulWidget {
  const SearchDialog({
    super.key,
    required this.onSearchSelected,
    required this.onSearchCleared,
    this.initialQuery,
  });

  final ValueSetter<OneMapSearchData> onSearchSelected;
  final VoidCallback onSearchCleared;
  final String? initialQuery;

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  late Future<OneMapSearch> _searchResults;
  late Future<BusStopSearchApiResponse> _futureBusStopSearchResults;
  late Future<BusServiceSearchApiResponse> _futureBusServiceSearchResults;

  Timer? _debounce;
  final _textFieldController = TextEditingController();
  late final FocusNode _searchFocusNode = FocusNode();

  SearchMode _searchMode = SearchMode.PLACES; // Default search mode

  Future<OneMapSearch> searchPlaces(String query, int page) async {
    if (query.isEmpty) {
      return Future.value(OneMapSearch(totalCount: 0, count: 0, totalPages: 0, page: 1, data: []));
    }

    final response = await http.get(
      Uri.parse('${Secret.API_URL}/onemap/search?query=$query&page=$page'),
    );

    if (response.statusCode == 200) {
      return OneMapSearch.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load search results');
    }
  }

  Future<BusStopSearchApiResponse> searchBusStops(String query) async {
    if (query.isEmpty) {
      return Future.value(BusStopSearchApiResponse(
        message: "NA",
        count: 0,
        data: [],
      ));
    }

    final response = await http.get(
      Uri.parse('${Secret.API_URL}/search/bus-stops?query=$query'),
    );

    if (response.statusCode == 200) {
      debugPrint("Services fetched");
      return BusStopSearchApiResponse.fromJson(json.decode(response.body));
    } else {
      debugPrint("Error fetching bus stop search results");
      throw Exception("Error fetching bus stop search results");
    }
  }

  Future<BusServiceSearchApiResponse> searchBusServices(String query) async {
    if (query.isEmpty) {
      return Future.value(BusServiceSearchApiResponse(
        message: "NA",
        count: 0,
        data: [],
      ));
    }

    final response = await http.get(
      Uri.parse('${Secret.API_URL}/search/bus-services?query=$query'),
    );

    if (response.statusCode == 200) {
      debugPrint("Services fetched");
      return BusServiceSearchApiResponse.fromJson(json.decode(response.body));
    } else {
      debugPrint("Error fetching bus service search results");
      throw Exception("Error fetching bus service search results");
    }
  }

  // debounces the search query to prevent spamming the api
  void _onSearchChanged(String query, int page) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: query.length < 3 ? 0 : 200), () {
      switch (_searchMode) {
        case SearchMode.PLACES:
          setState(() {
            _searchResults = searchPlaces(query, page);
          });
          break;
        case SearchMode.STOPS:
          setState(() {
            _futureBusStopSearchResults = searchBusStops(query);
          });
          break;
        case SearchMode.SERVICES:
          setState(() {
            _futureBusServiceSearchResults = searchBusServices(query);
          });
          break;
      }
    });
  }

  void clearSearch() {
    _textFieldController.clear();
    setState(() {
      _searchResults = Future.value(OneMapSearch(
        totalCount: 0,
        count: 0,
        totalPages: 0,
        page: 1,
        data: [],
      ));

      _futureBusStopSearchResults = Future.value(BusStopSearchApiResponse(
        message: "NA",
        count: 0,
        data: [],
      ));

      _futureBusServiceSearchResults = Future.value(BusServiceSearchApiResponse(
        message: "NA",
        count: 0,
        data: [],
      ));
    });
    widget.onSearchCleared();
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

    _futureBusStopSearchResults = Future.value(BusStopSearchApiResponse(
      message: "NA",
      count: 0,
      data: [],
    ));

    _futureBusServiceSearchResults = Future.value(BusServiceSearchApiResponse(
      message: "NA",
      count: 0,
      data: [],
    ));

    if (widget.initialQuery != null) {
      _textFieldController.text = widget.initialQuery!;
      _onSearchChanged(widget.initialQuery!, 1);
    }
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
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              curve: Easing.standard,
              opacity: _textFieldController.text.isNotEmpty ? 1.0 : 0.0,
              child: IconButton(
                icon: const AppSymbol(Symbols.clear_rounded),
                onPressed: () => clearSearch(),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Row(
                  spacing: 8,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    ChoiceChip(
                      label: Text("Places"),
                      selected: _searchMode == SearchMode.PLACES,
                      onSelected: (value) {
                        setState(() => _searchMode = SearchMode.PLACES);
                        _textFieldController.clear();
                      },
                      avatar: AnimatedOpacity(
                          opacity: _searchMode == SearchMode.PLACES ? 0.2 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Easing.standard,
                          child: AppSymbol(
                            Symbols.place_rounded,
                            fill: true,
                          )),
                    ),
                    ChoiceChip(
                      label: Text("Bus Stops"),
                      selected: _searchMode == SearchMode.STOPS,
                      onSelected: (value) {
                        setState(() => _searchMode = SearchMode.STOPS);
                        _textFieldController.clear();
                      },
                      avatar: AnimatedOpacity(
                          opacity: _searchMode == SearchMode.STOPS ? 0.2 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Easing.standard,
                          child: AppSymbol(
                            Symbols.signpost_rounded,
                            fill: true,
                          )),
                    ),
                    ChoiceChip(
                      label: Text("Bus Services"),
                      selected: _searchMode == SearchMode.SERVICES,
                      onSelected: (value) {
                        setState(() => _searchMode = SearchMode.SERVICES);
                        _textFieldController.clear();
                      },
                      avatar: AnimatedOpacity(
                          opacity: _searchMode == SearchMode.SERVICES ? 0.2 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Easing.standard,
                          child: AppSymbol(
                            Symbols.directions_bus_rounded,
                            fill: true,
                          )),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (_textFieldController.text.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(left: 4.0, top: 8.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Theme.of(context).colorScheme.surface,
                                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.0),
                                ],
                                stops: [0.85, 1.0],
                              ),
                            ),
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
                          RecentSearchList(
                            onSearchCardSelected: (value) {
                              widget.onSearchSelected(value);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  } else if (_searchMode == SearchMode.PLACES) {
                    return placesSearchResults();
                  } else if (_searchMode == SearchMode.STOPS) {
                    return busStopSearchResults();
                  } else if (_searchMode == SearchMode.SERVICES) {
                    return busServiceSearchResults();
                  } else {
                    return Container();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  FutureBuilder<OneMapSearch> placesSearchResults() {
    return FutureBuilder<OneMapSearch>(
      future: _searchResults,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          OneMapSearch res = snapshot.data!;

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
    );
  }

  FutureBuilder<BusStopSearchApiResponse> busStopSearchResults() {
    return FutureBuilder(
        future: _futureBusStopSearchResults,
        builder: (BuildContext context, AsyncSnapshot<BusStopSearchApiResponse> snapshot) {
          // if the bus stop list is not yet loaded, show a loading indicator
          if (snapshot.hasData) {
            BusStopSearchApiResponse res = snapshot.data!;

            if (res.count == 0 && snapshot.connectionState == ConnectionState.done) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "🔍 We couldn't find any bus stops 🤔",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Try checking search for typos or use a different search term",
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
                      height: 79,
                      borderRadius: BorderRadius.circular(12),
                      padding: const EdgeInsets.only(bottom: 16)),
                ),
              ),
              child: ListView.separated(
                itemCount: res.count,
                padding: const EdgeInsets.only(top: 16.0, bottom: 32.0, left: 12.0, right: 12.0),
                itemBuilder: (BuildContext context, int index) {
                  return BusStopCard(busStopInfo: res.data[index], searchMode: true);
                },
                separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 16),
              ),
            );
          } else if (snapshot.hasError) {
            // return Text("${snapshot.error}");
            debugPrint("<=== ERROR ${snapshot.error} ===>");
            return const ErrorText();
          }

          return const Center(child: CircularProgressIndicator(strokeWidth: 3));
        });
  }

  FutureBuilder<BusServiceSearchApiResponse> busServiceSearchResults() {
    return FutureBuilder(
      future: _futureBusServiceSearchResults,
      builder: (BuildContext context, AsyncSnapshot<BusServiceSearchApiResponse> snapshot) {
        // if the bus service list is not yet loaded, show a loading indicator
        if (snapshot.hasData) {
          BusServiceSearchApiResponse res = snapshot.data!;

          if (res.count == 0 && snapshot.connectionState == ConnectionState.done) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "🔍 We couldn't find any bus services 🤔",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Are you sure you typed the correct bus service number?",
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
                    height: 79,
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.only(bottom: 16)),
              ),
            ),
            child: ListView.separated(
              itemCount: res.count,
              padding: const EdgeInsets.only(top: 16.0, bottom: 32.0, left: 12.0, right: 12.0),
              itemBuilder: (BuildContext context, int index) {
                return BusServiceCard(busServiceInfo: res.data[index]);
              },
              separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 16),
            ),
          );
        } else if (snapshot.hasError) {
          // return Text("${snapshot.error}");
          debugPrint("<=== ERROR ${snapshot.error} ===>");
          return const ErrorText();
        }

        return const Center(child: CircularProgressIndicator(strokeWidth: 3));
      },
    );
  }
}
