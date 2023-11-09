// FIXME - yeahhh this screen needs to get fully refactored

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:transito/models/api/transito/bus_services.dart';
import 'package:transito/models/api/transito/bus_stops.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/models/secret.dart';
import 'package:transito/widgets/bus_info/bus_service_card.dart';
import 'package:transito/widgets/bus_info/bus_stop_card.dart';
import 'package:transito/widgets/common/error_text.dart';
import 'package:http/http.dart' as http;

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  late Future<BusStopSearchApiResponse> _futureBusStopSearchResults;
  late Future<List<BusService>> _futureBusServiceSearchResults; // TODO - Update typing

  late TabController _tabController;
  Timer? _debounce;
  final _textFieldController = TextEditingController();

  // tabs to switch between bus stops and bus services
  static const List<Tab> searchTabs = <Tab>[
    Tab(text: 'Bus Stops'),
    Tab(text: 'Bus Services'),
  ];

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (_tabController.index == 0) {
        setState(() {
          _futureBusStopSearchResults = searchBusStops(query);
          ;
        });
      } else {
        // TODO - Call func to search for bus services
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

  // initializes the screen
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: searchTabs.length, vsync: this, initialIndex: 0);
    _futureBusStopSearchResults = searchBusStops('');
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
          indicatorColor: AppColors.accentColour,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          busStopView(),
          // busServiceView(),
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

            return ListView.separated(
              itemCount: res.count,
              padding: const EdgeInsets.only(top: 16.0, bottom: 32.0, left: 12.0, right: 12.0),
              itemBuilder: (BuildContext context, int index) {
                return BusStopCard(busStopInfo: res.data[index], searchMode: true);
              },
              separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 16),
            );
          } else if (snapshot.hasError) {
            // return Text("${snapshot.error}");
            debugPrint("<=== ERROR ${snapshot.error} ===>");
            return const ErrorText();
          } else {
            return const Center(child: CircularProgressIndicator(strokeWidth: 3));
          }
        });
  }

  // listview for the bus services tab
  Widget busServiceView() {
    return FutureBuilder(
      future: _futureBusServiceSearchResults,
      builder: (BuildContext context, AsyncSnapshot<List<BusService>> snapshot) {
        // if the bus service list is not yet loaded, show a loading indicator
        if (snapshot.hasData) {
          List<BusService> res = snapshot.data!;

          return ListView.separated(
            itemCount: res.length,
            padding: const EdgeInsets.only(top: 16.0, bottom: 32.0, left: 12.0, right: 12.0),
            itemBuilder: (BuildContext context, int index) {
              return BusServiceCard(busServiceInfo: res[index]);
            },
            separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 16),
          );
        } else {
          return const Center(child: CircularProgressIndicator(strokeWidth: 3));
        }
      },
    );
  }
}
