import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_skeleton_ui/flutter_skeleton_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/search_provider.dart';
import 'package:transito/global/services/transito_api_service.dart';
import 'package:transito/models/api/transito/bus_services.dart';
import 'package:transito/models/api/transito/bus_stops.dart';
import 'package:transito/models/api/transito/onemap/onemap_search.dart';
import 'package:transito/models/enums/search_mode_enum.dart';
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
    return TransitoApiService().searchPlaces(query, page);
  }

  Future<BusStopSearchApiResponse> searchBusStops(String query) async {
    if (query.isEmpty) {
      return Future.value(
        BusStopSearchApiResponse(
          message: "NA",
          count: 0,
          data: [],
        ),
      );
    }

    final BusStopSearchApiResponse response = await TransitoApiService().searchBusStops(query);
    debugPrint("Services fetched");
    return response;
  }

  Future<BusServiceSearchApiResponse> searchBusServices(String query) async {
    if (query.isEmpty) {
      return Future.value(
        BusServiceSearchApiResponse(
          message: "NA",
          count: 0,
          data: [],
        ),
      );
    }

    final BusServiceSearchApiResponse response = await TransitoApiService().searchBusServices(
      query,
    );
    debugPrint("Services fetched");
    return response;
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
      _searchResults = Future.value(
        OneMapSearch(
          totalCount: 0,
          count: 0,
          totalPages: 0,
          page: 1,
          data: [],
        ),
      );

      _futureBusStopSearchResults = Future.value(
        BusStopSearchApiResponse(
          message: "NA",
          count: 0,
          data: [],
        ),
      );

      _futureBusServiceSearchResults = Future.value(
        BusServiceSearchApiResponse(
          message: "NA",
          count: 0,
          data: [],
        ),
      );
    });
    widget.onSearchCleared();
  }

  @override
  void initState() {
    super.initState();
    _searchResults = Future.value(
      OneMapSearch(
        totalCount: 0,
        count: 0,
        totalPages: 0,
        page: 1,
        data: [],
      ),
    );

    _futureBusStopSearchResults = Future.value(
      BusStopSearchApiResponse(
        message: "NA",
        count: 0,
        data: [],
      ),
    );

    _futureBusServiceSearchResults = Future.value(
      BusServiceSearchApiResponse(
        message: "NA",
        count: 0,
        data: [],
      ),
    );

    if (widget.initialQuery != null) {
      _textFieldController.text = widget.initialQuery!;
      _onSearchChanged(widget.initialQuery!, 1);
    }
  }

  Widget searchErrorText() {
    return const ErrorText(
      title: 'Search is taking a break',
      message: 'Give it another try in a moment.',
      icon: Symbols.search_off_rounded,
    );
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
          shape: RoundedRectangleBorder(),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          scrolledUnderElevation: 0,
          title: TextField(
            controller: _textFieldController,
            focusNode: _searchFocusNode,
            autofocus: true,
            onChanged: (_) => _onSearchChanged(_textFieldController.text, 1),
            keyboardType: _searchMode == SearchMode.SERVICES
                ? TextInputType.numberWithOptions(decimal: false)
                : TextInputType.text,
            decoration: InputDecoration(
              hintText: 'Search...',
              isDense: false,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
            onTapOutside: (event) => _searchFocusNode.unfocus(),
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
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(bottom: 8, left: 16, right: 16),
                child: Row(
                  spacing: 8,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    ChoiceChip(
                      label: Text("Places"),
                      selected: _searchMode == SearchMode.PLACES,
                      onSelected: (value) {
                        if (_searchMode == SearchMode.SERVICES) _textFieldController.clear();

                        setState(() => _searchMode = SearchMode.PLACES);
                        _onSearchChanged(_textFieldController.text, 1);

                        if (_textFieldController.text.isEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _searchFocusNode.requestFocus();
                          });
                        }
                      },
                      avatar: AnimatedOpacity(
                        opacity: _searchMode == SearchMode.PLACES ? 0.2 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Easing.standard,
                        child: AppSymbol(
                          Symbols.place_rounded,
                          fill: true,
                        ),
                      ),
                    ),
                    ChoiceChip(
                      label: Text("Bus Stops"),
                      selected: _searchMode == SearchMode.STOPS,
                      onSelected: (value) {
                        if (_searchMode == SearchMode.SERVICES) _textFieldController.clear();

                        setState(() => _searchMode = SearchMode.STOPS);
                        _onSearchChanged(_textFieldController.text, 1);

                        if (_textFieldController.text.isEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _searchFocusNode.requestFocus();
                          });
                        }
                      },
                      avatar: AnimatedOpacity(
                        opacity: _searchMode == SearchMode.STOPS ? 0.2 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Easing.standard,
                        child: AppSymbol(
                          Symbols.signpost_rounded,
                          fill: true,
                        ),
                      ),
                    ),
                    ChoiceChip(
                      label: Text("Bus Services"),
                      selected: _searchMode == SearchMode.SERVICES,
                      onSelected: (value) {
                        _textFieldController.clear();

                        setState(() {
                          _searchMode = SearchMode.SERVICES;
                        });

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _searchFocusNode.requestFocus();
                        });
                      },
                      avatar: AnimatedOpacity(
                        opacity: _searchMode == SearchMode.SERVICES ? 0.2 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Easing.standard,
                        child: AppSymbol(
                          Symbols.directions_bus_rounded,
                          fill: true,
                        ),
                      ),
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
            return const ErrorText(
              title: 'No places found',
              message: 'Try a nearby landmark or address instead.',
              icon: Symbols.not_listed_location_rounded,
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
          return searchErrorText();
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
            return const ErrorText(
              title: 'No bus stops found',
              message: 'Try another stop name, or check for typos.',
              icon: Symbols.bus_map_pin_rounded, // TODO - find a better icon for this
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
                  padding: const EdgeInsets.only(bottom: 16),
                ),
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
          return searchErrorText();
        }

        return const Center(child: CircularProgressIndicator(strokeWidth: 3));
      },
    );
  }

  FutureBuilder<BusServiceSearchApiResponse> busServiceSearchResults() {
    return FutureBuilder(
      future: _futureBusServiceSearchResults,
      builder: (BuildContext context, AsyncSnapshot<BusServiceSearchApiResponse> snapshot) {
        // if the bus service list is not yet loaded, show a loading indicator
        if (snapshot.hasData) {
          BusServiceSearchApiResponse res = snapshot.data!;

          if (res.count == 0 && snapshot.connectionState == ConnectionState.done) {
            return const ErrorText(
              title: 'No bus services found',
              message: 'Are you sure the service exists?',
              icon: Symbols.no_transfer_rounded,
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
                  padding: const EdgeInsets.only(bottom: 16),
                ),
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
          return searchErrorText();
        }

        return const Center(child: CircularProgressIndicator(strokeWidth: 3));
      },
    );
  }
}
