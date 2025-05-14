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
  int _pageIndex = 0;
  final controller = PageController(
    initialPage: 0,
    keepPage: true,
  );

  // Screens to be displayed by the bottom navigation bar
  List<StatefulWidget> widgetList = const [
    NearbyScreen(),
    FavouritesScreen(),
    RecentSearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    bool isTablet = context.read<CommonProvider>().isTablet; //REVIEW - Check if this is still needed

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
          children: widgetList,
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
                duration: const Duration(milliseconds: 300), curve: Curves.ease);
          });
        },
      ),
    );
  }
}
