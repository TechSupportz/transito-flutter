import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_skeleton_ui/flutter_skeleton_ui.dart';
import 'package:http/http.dart' as http;
import 'package:transito/models/api/transito/bus_services.dart';
import 'package:transito/models/api/transito/bus_stops.dart';
import 'package:transito/models/secret.dart';
import 'package:transito/widgets/bus_info/bus_service_card.dart';
import 'package:transito/widgets/bus_info/bus_stop_card.dart';
import 'package:transito/widgets/common/error_text.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  late Future<BusStopSearchApiResponse> _futureBusStopSearchResults;
  late Future<BusServiceSearchApiResponse> _futureBusServiceSearchResults;

  late TabController _tabController;
  Timer? _debounce;
  final _textFieldController = TextEditingController();
  late final FocusNode _searchFocusNode = FocusNode();

  // tabs to switch between bus stops and bus services
  static const List<Tab> searchTabs = <Tab>[
    Tab(text: 'Bus Stops'),
    Tab(text: 'Bus Services'),
  ];

  // debounces the search query to prevent spamming the api
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: query.length < 3 ? 0 : 200), () {
      if (_tabController.index == 0) {
        setState(() {
          _futureBusStopSearchResults = searchBusStops(query);
        });
      } else {
        if (query.isEmpty) return;

        setState(() {
          _futureBusServiceSearchResults = searchBusServices(query);
        });
      }
    });
  }

  Future<BusStopSearchApiResponse> searchBusStops(String query) async {
    final response = await http.get(Uri.parse('${Secret.API_URL}/search/bus-stops?query=$query'));

    if (response.statusCode == 200) {
      debugPrint("Services fetched");
      return BusStopSearchApiResponse.fromJson(json.decode(response.body));
    } else {
      debugPrint("Error fetching bus stop search results");
      throw Exception("Error fetching bus stop search results");
    }
  }

  Future<BusServiceSearchApiResponse> searchBusServices(String query) async {
    final response =
        await http.get(Uri.parse('${Secret.API_URL}/search/bus-services?query=$query'));

    if (response.statusCode == 200) {
      debugPrint("Services fetched");
      return BusServiceSearchApiResponse.fromJson(json.decode(response.body));
    } else {
      debugPrint("Error fetching bus service search results");
      throw Exception("Error fetching bus service search results");
    }
  }

  // initializes the screen
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: searchTabs.length, vsync: this, initialIndex: 0);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _textFieldController.clear();

          // Only enabled on iOS cause it looks too jank on android
          if (Platform.isIOS) {
            _searchFocusNode.unfocus();
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _searchFocusNode.requestFocus(),
            );
          }
        });
      }
    });

    _futureBusStopSearchResults = Future(() => BusStopSearchApiResponse(
          message: "NA",
          count: 0,
          data: [],
        ));
    _futureBusServiceSearchResults = Future(() => BusServiceSearchApiResponse(
          message: "NA",
          count: 0,
          data: [],
        ));
  }

  // disposes of tab controller when the screen exited
  @override
  void dispose() {
    _tabController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _textFieldController,
          focusNode: _searchFocusNode,
          autofocus: true,
          keyboardType: _tabController.index == 0 ? TextInputType.text : TextInputType.number,
          onChanged: (_) => _onSearchChanged(_textFieldController.text),
          // enabled: _busStopList.isNotEmpty,
          decoration: InputDecoration(
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                // clears the search field
                _textFieldController.clear();
              },
            ),
            hintText: 'Search...',
            isDense: false,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: searchTabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          busStopView(),
          busServiceView(),
        ],
      ),
    );
  }

  // listview for the bus stops tab
  Widget busStopView() {
    return FutureBuilder(
        future: _futureBusStopSearchResults,
        builder: (BuildContext context, AsyncSnapshot<BusStopSearchApiResponse> snapshot) {
          // if the bus stop list is not yet loaded, show a loading indicator
          if (snapshot.hasData) {
            BusStopSearchApiResponse res = snapshot.data!;

            if (res.count == 0 && _textFieldController.text.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "🔍 Start typing to find a bus stop 🚏",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "You can search by the bus stop code, \n name or road name",
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

  // listview for the bus services tab
  Widget busServiceView() {
    return FutureBuilder(
      future: _futureBusServiceSearchResults,
      builder: (BuildContext context, AsyncSnapshot<BusServiceSearchApiResponse> snapshot) {

        // if the bus service list is not yet loaded, show a loading indicator
        if (snapshot.hasData) {
          BusServiceSearchApiResponse res = snapshot.data!;

          if (res.count == 0 && _textFieldController.text.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "🔍 Start typing to find a bus service 🚍",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Just enter in the bus service number",
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
