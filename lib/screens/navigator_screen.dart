import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/common_provider.dart';
import 'package:transito/screens/favourites/favourites_screen.dart';
import 'package:transito/screens/main/nearby_screen.dart';
import 'package:transito/screens/search/recent_search_screen.dart';
import 'package:upgrader/upgrader.dart';

class NavigatorScreen extends StatefulWidget {
  const NavigatorScreen({super.key});

  @override
  State<NavigatorScreen> createState() => _NavigatorScreenState();
}

class _NavigatorScreenState extends State<NavigatorScreen> {
  late final PageController controller;
  int _pageIndex = 0;
  final List<Widget> _pages = const [
    NearbyScreen(),
    FavouritesScreen(),
    RecentSearchScreen(),
  ];

  @override
  void initState() {
    super.initState();
    controller = PageController(initialPage: _pageIndex, keepPage: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: UpgradeAlert(
        upgrader: Upgrader(
          countryCode: "SG",
        ),
        child: PageView(
          controller: controller,
          pageSnapping: true,
          dragStartBehavior: DragStartBehavior.start,
          onPageChanged: (index) {
            setState(() => _pageIndex = index);
          },
          children: _pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.explore_rounded), label: "Nearby"),
          NavigationDestination(icon: Icon(Icons.favorite_rounded), label: "Favourites"),
          NavigationDestination(icon: Icon(Icons.search_rounded), label: "Search"),
        ],
        selectedIndex: _pageIndex,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: (index) {
          // updates _pageIndex and animates the page transition
          setState(() {
            _pageIndex = index;
            controller.animateToPage(index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubicEmphasized);
          });
        },
      ),
    );
  }
}
