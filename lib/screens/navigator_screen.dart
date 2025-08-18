import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:transito/screens/favourites/favourites_screen.dart';
import 'package:transito/screens/main/mrt_map_screen.dart';
import 'package:transito/screens/main/nearby_screen.dart';
import 'package:transito/screens/search/map_search_screen.dart';
import 'package:transito/widgets/common/animated_index_stack.dart';
import 'package:upgrader/upgrader.dart';

class NavigatorScreen extends StatefulWidget {
  const NavigatorScreen({super.key, this.initialPageIndex = 0});
  final int initialPageIndex;

  @override
  State<NavigatorScreen> createState() => _NavigatorScreenState();
}

class _NavigatorScreenState extends State<NavigatorScreen> {
  int _pageIndex = 0;
  final List<Widget> _pages = const [
    NearbyScreen(),
    FavouritesScreen(),
    MapSearchScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.initialPageIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: UpgradeAlert(
          upgrader: Upgrader(
            countryCode: "SG",
          ),
          child: AnimatedIndexedStack(
            transitionBuilder: (
              Widget child,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) {
              return FadeThroughTransition(
                animation: animation,
                secondaryAnimation: secondaryAnimation,
                child: child,
              );
            },
            index: _pageIndex,
            children: _pages,
          )),
      bottomNavigationBar: NavigationBar(
        destinations: <NavigationDestination>[
          NavigationDestination(icon: Icon(Symbols.explore_rounded, fill: 1), label: "Nearby"),
          NavigationDestination(icon: Icon(Symbols.favorite_rounded, fill: 1), label: "Favourites"),
          NavigationDestination(
              icon: GestureDetector(
                child: Icon(Symbols.map_search_rounded, fill: 1),
                onTap: () => setState(() {
                  _pageIndex = 2;
                }),
                onDoubleTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MrtMapScreen(),
                    settings: RouteSettings(name: 'MrtMapScreen'),
                  ),
                ),
              ),
              label: "Search"),
        ],
        selectedIndex: _pageIndex,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: (index) {
          // updates _pageIndex and animates the page transition
          setState(() {
            _pageIndex = index;
          });
        },
      ),
    );
  }
}
