// FIXME - yeahhh this screen needs to get fully refactored

// import 'dart:convert';

// import 'package:collection/collection.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:transito/models/api/transito/bus_services.dart';

// import 'package:transito/models/api/transito/bus_stops.dart';
// import 'package:transito/models/app/app_colors.dart';
// import 'package:transito/widgets/bus_info/bus_service_card.dart';
// import 'package:transito/widgets/bus_info/bus_stop_card.dart';
// import 'package:transito/widgets/common/error_text.dart';

// class SearchScreen extends StatefulWidget {
//   const SearchScreen({Key? key}) : super(key: key);

//   @override
//   State<SearchScreen> createState() => _SearchScreenState();
// }

// class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
//   late Future<List<BusStopInfo>> _futureBusStopList;
//   List<BusStopInfo> _filteredBusStopList = [];
//   List<BusStopInfo> _busStopList = [];

//   late Future<List<BusServiceInfo>> _futureBusServiceList;
//   List<BusServiceInfo> _filteredBusServiceList = [];
//   List<BusServiceInfo> _busServiceList = [];

//   late TabController _tabController;
//   final _textFieldController = TextEditingController();

//   // tabs to switch between bus stops and bus services
//   static const List<Tab> searchTabs = <Tab>[
//     Tab(text: 'Bus Stops'),
//     Tab(text: 'Bus Services'),
//   ];

//   // fetches bus stop data from the assets/data/bus_stops.json file and assigns it to respective variables
//   Future<List<BusStopInfo>> fetchBusStops() async {
//     debugPrint("Fetching bus stops");
//     final String response = await rootBundle.loadString('assets/bus_stops.json');
//     setState(() {
//       _busStopList = NearbyBusStop.fromJson(jsonDecode(response)).busStops;
//       _filteredBusStopList = NearbyBusStop.fromJson(jsonDecode(response)).busStops;
//     });
//     return NearbyBusStop.fromJson(jsonDecode(response)).busStops;
//   }

//   // fetches bus service data from the assets/data/bus_services.json file and assigns it to respective variables
//   Future<List<BusServiceInfo>> fetchBusServices() async {
//     debugPrint("Fetching bus stops");
//     final String response = await rootBundle.loadString('assets/bus_services.json');
//     var busServices = AllBusServices.fromJson(jsonDecode(response)).busServices;
//     // removes duplicate bus services due to api returning one for each direction
//     busServices = busServices.where((element) => element.direction != 2).toList();
//     // sorts bus services by service number
//     busServices.sort((a, b) => compareNatural(a.serviceNo, b.serviceNo));
//     setState(() {
//       _busServiceList = busServices;
//       _filteredBusServiceList = busServices;
//     });
//     return AllBusServices.fromJson(jsonDecode(response)).busServices;
//   }

//   void filterBusStops() {
//     // the toLowerCase() methods makes search case-insensitive
//     final String searchText = _textFieldController.text.toLowerCase();
//     List<BusStopInfo> _results = [];

//     if (searchText.trim().isEmpty && _busStopList.isNotEmpty) {
//       // if the search field is empty or only contains white-space, show all bus stops
//       _results = _busStopList;
//     } else {
//       _results = _busStopList
//           .where((BusStopInfo busStopInfo) =>
//               busStopInfo.name.toLowerCase().contains(searchText) ||
//               busStopInfo.code.toLowerCase().contains(searchText) ||
//               busStopInfo.roadName.toLowerCase().contains(searchText))
//           .toList();
//     }
//     // updates the filtered bus stop list
//     setState(() {
//       _filteredBusStopList = _results;
//     });
//   }

//   void filterBusServices() {
//     // the toLowerCase() methods makes search case-insensitive
//     final String searchText = _textFieldController.text.toLowerCase();
//     List<BusServiceInfo> _results = [];
//     List<BusServiceInfo> _sortedResults = [];

//     if (searchText.trim().isEmpty && _busServiceList.isNotEmpty) {
//       // if the search field is empty or only contains white-space, show all bus services
//       _results = _busServiceList;
//     } else {
//       _results = _busServiceList
//           .where((BusServiceInfo busServiceInfo) =>
//               busServiceInfo.serviceNo.toLowerCase().contains(searchText))
//           .toList();
//     }
//     // sorts bus services by service number
//     _sortedResults = _results;
//     _sortedResults.sort((a, b) => compareNatural(a.serviceNo, b.serviceNo));
//     // updates the filtered bus service list
//     setState(() {
//       _filteredBusServiceList = _sortedResults;
//     });
//   }

//   // initializes the screen
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: searchTabs.length, vsync: this, initialIndex: 0);
//     _futureBusStopList = fetchBusStops();
//     _futureBusServiceList = fetchBusServices();
//   }

//   // disposes of tab controller when the screen exited
//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: TextField(
//           controller: _textFieldController,
//           onChanged: (_) => _tabController.index == 0 ? filterBusStops() : filterBusServices(),
//           // enabled: _busStopList.isNotEmpty,
//           decoration: InputDecoration(
//             suffixIcon: IconButton(
//               icon: const Icon(Icons.clear),
//               onPressed: () {
//                 // clears the search field and updates the filtered bus stop/bus services list depending on tab
//                 _textFieldController.clear();
//                 if (_tabController.index == 0) {
//                   setState(() {
//                     _filteredBusStopList = _busStopList;
//                   });
//                 } else {
//                   setState(() {
//                     _filteredBusServiceList = _busServiceList;
//                   });
//                 }
//               },
//             ),
//             hintText: 'Search...',
//             isDense: false,
//             filled: false,
//             border: InputBorder.none,
//             enabledBorder: InputBorder.none,
//           ),
//         ),
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: searchTabs,
//           indicatorColor: AppColors.accentColour,
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           busStopView(),
//           busServiceView(),
//         ],
//       ),
//     );
//   }

//   // listview for the bus stops tab
//   Widget busStopView() {
//     return FutureBuilder(
//         future: _futureBusStopList,
//         builder: (BuildContext context, AsyncSnapshot<List<BusStopInfo>> snapshot) {
//           // if the bus stop list is not yet loaded, show a loading indicator
//           if (snapshot.hasData) {
//             return ListView.separated(
//               itemCount: _filteredBusStopList.length,
//               padding: const EdgeInsets.only(top: 16.0, bottom: 32.0, left: 12.0, right: 12.0),
//               itemBuilder: (BuildContext context, int index) {
//                 return BusStopCard(busStopInfo: _filteredBusStopList[index], searchMode: true);
//               },
//               separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 16),
//             );
//           } else if (snapshot.hasError) {
//             // return Text("${snapshot.error}");
//             debugPrint("<=== ERROR ${snapshot.error} ===>");
//             return const ErrorText();
//           } else {
//             return const Center(child: CircularProgressIndicator(strokeWidth: 3));
//           }
//         });
//   }

//   // listview for the bus services tab
//   Widget busServiceView() {
//     return FutureBuilder(
//       future: _futureBusServiceList,
//       builder: (BuildContext context, AsyncSnapshot<List<BusServiceInfo>> snapshot) {
//         // if the bus service list is not yet loaded, show a loading indicator
//         if (snapshot.hasData) {
//           return ListView.separated(
//             itemCount: _filteredBusServiceList.length,
//             padding: const EdgeInsets.only(top: 16.0, bottom: 32.0, left: 12.0, right: 12.0),
//             itemBuilder: (BuildContext context, int index) {
//               return BusServiceCard(busServiceInfo: _filteredBusServiceList[index]);
//             },
//             separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 16),
//           );
//         } else {
//           return const Center(child: CircularProgressIndicator(strokeWidth: 3));
//         }
//       },
//     );
//   }
// }
