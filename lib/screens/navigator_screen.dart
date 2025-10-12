import 'dart:io';

import 'package:animations/animations.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/common_provider.dart';
import 'package:transito/screens/favourites/favourites_screen.dart';
import 'package:transito/screens/main/mrt_map_screen.dart';
import 'package:transito/screens/main/nearby_screen.dart';
import 'package:transito/screens/search/map_search_screen.dart';
import 'package:transito/widgets/common/animated_index_stack.dart';
import 'package:transito/widgets/common/app_symbol.dart';
import 'package:upgrader/upgrader.dart';

class NavigatorScreen extends StatefulWidget {
  const NavigatorScreen({super.key, this.initialPageIndex = 0});
  final int initialPageIndex;

  @override
  State<NavigatorScreen> createState() => _NavigatorScreenState();
}

class _NavigatorScreenState extends State<NavigatorScreen> {
  int _pageIndex = 0;

  final NearbyScreenController _nearbyScreenController = NearbyScreenController();
  final FavouritesScreenController _favouritesScreenController = FavouritesScreenController();
  final MapSearchScreenController _mapSearchScreenController = MapSearchScreenController();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.initialPageIndex;

    _pages = [
      NearbyScreen(controller: _nearbyScreenController),
      FavouritesScreen(controller: _favouritesScreenController),
      MapSearchScreen(controller: _mapSearchScreenController),
    ];
  }

  @override
  Widget build(BuildContext context) {
    bool supportsLiquidGlass = context.watch<CommonProvider>().supportsLiquidGlass;
    bool isUserCenter = context.watch<CommonProvider>().isUserCenter;

    var navigationBar = NavigationBar(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      destinations: <NavigationDestination>[
        NavigationDestination(
            icon: AppSymbol(Symbols.explore_rounded, fill: true), label: "Nearby"),
        NavigationDestination(
            icon: AppSymbol(Symbols.favorite_rounded, fill: true), label: "Favourites"),
        NavigationDestination(
            icon: GestureDetector(
              child: AppSymbol(Symbols.map_search_rounded, fill: true),
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
      onDestinationSelected: (index) =>
          // updates _pageIndex and animates the page transition
          setState(() {
        _pageIndex = index;
      }),
    );

    return Scaffold(
      body: UpgradeAlert(
        upgrader: Upgrader(
          countryCode: "SG",
        ),
        child: Stack(
          children: [
            AnimatedIndexedStack(
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
            ),
            if (Platform.isIOS && supportsLiquidGlass)
              Align(
                alignment: Alignment.bottomCenter,
                child: CNTabBar(
                  items: [
                    CNTabBarItem(label: 'Nearby', icon: CNSymbol('safari.fill')),
                    CNTabBarItem(label: 'Favourites', icon: CNSymbol('heart.fill')),
                    CNTabBarItem(label: 'Search', icon: CNSymbol('map.fill')),
                    CNTabBarItem(
                        icon: _pageIndex == 0
                            ? CNSymbol('arrow.clockwise')
                            : _pageIndex == 1
                                ? CNSymbol('pencil')
                                : _pageIndex == 2
                                    ? isUserCenter
                                        ? CNSymbol('location.fill')
                                        : CNSymbol('location')
                                    : CNSymbol('circle')),
                  ],
                  currentIndex: _pageIndex,
                  split: true,
                  rightCount: 1,
                  splitSpacing: 1.0,
                  shrinkCentered: false,
                  onTap: (index) {
                    if (index == 3) {
                      switch (_pageIndex) {
                        case 0:
                          _nearbyScreenController.refresh();
                          break;
                        case 1:
                          _favouritesScreenController.manageFavourites();
                          break;
                        case 2:
                          _mapSearchScreenController.animateToUserLocation();
                          break;
                        default:
                      }

                      setState(() => _pageIndex = _pageIndex);
                      return;
                    }

                    setState(() {
                      _pageIndex = index;
                    });
                  },
                ),
              )
          ],
        ),
      ),
      bottomNavigationBar: Platform.isIOS && supportsLiquidGlass ? null : navigationBar,
    );
  }
}
