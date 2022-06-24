import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:transito/models/app_colors.dart';

import '../models/bus_stops.dart';
import '../widgets/bus_stop_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  late Future<List<BusStopInfo>> _futureBusStopList;
  List<BusStopInfo> _filteredBusStopList = [];
  List<BusStopInfo> _busStopList = [];
  late TabController _tabController;
  final _textFieldController = TextEditingController();

  static const List<Tab> searchTabs = <Tab>[
    Tab(text: 'Bus Stops'),
    Tab(text: 'Bus Services'),
  ];

  Future<List<BusStopInfo>> fetchBusStops() async {
    debugPrint("Fetching bus stops");
    final String response = await rootBundle.loadString('assets/bus_stops.json');
    setState(() {
      _busStopList = AllBusStops.fromJson(jsonDecode(response)).busStops;
      _filteredBusStopList = AllBusStops.fromJson(jsonDecode(response)).busStops;
    });
    return AllBusStops.fromJson(jsonDecode(response)).busStops;
  }

  void filterBusStops() {
    final String searchText = _textFieldController.text.toLowerCase();
    List<BusStopInfo> _results = [];

    if (searchText.isEmpty && _busStopList.isNotEmpty) {
      // if the search field is empty or only contains white-space, we'll display all users
      _results = _busStopList;
    } else {
      _results = _busStopList
          .where((BusStopInfo busStopInfo) =>
              busStopInfo.busStopName.toLowerCase().contains(searchText) ||
              busStopInfo.busStopCode.toLowerCase().contains(searchText) ||
              busStopInfo.roadName.toLowerCase().contains(searchText))
          .toList();
      // we use the toLowerCase() method to make it case-insensitive
    }
    setState(() {
      _filteredBusStopList = _results;
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: searchTabs.length, vsync: this, initialIndex: 0);
    _futureBusStopList = fetchBusStops();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _textFieldController,
          onChanged: (_) => filterBusStops(),
          // enabled: _busStopList.isNotEmpty,
          decoration: InputDecoration(
              suffixIcon: IconButton(
                icon: Hero(tag: 'SearchIcon', child: Icon(Icons.clear)),
                onPressed: () {
                  print('bruh');
                },
              ),
              hintText: 'Search...',
              border: InputBorder.none),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: searchTabs,
          indicatorColor: AppColors.veryPurple,
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

  Widget busStopView() {
    return FutureBuilder(
        future: _futureBusStopList,
        builder: (BuildContext context, AsyncSnapshot<List<BusStopInfo>> snapshot) {
          if (snapshot.hasData) {
            return ListView.separated(
              itemCount: _filteredBusStopList.length,
              padding: const EdgeInsets.only(top: 16.0, bottom: 32.0, left: 12.0, right: 12.0),
              itemBuilder: (BuildContext context, int index) {
                return BusStopCard(busStopInfo: _filteredBusStopList[index], searchMode: true);
              },
              separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 16),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }

  Widget busServiceView() {
    return Center(child: Text('Bus Services'));
  }
}
