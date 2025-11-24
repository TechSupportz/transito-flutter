import 'dart:io';

import 'package:animations/animations.dart';
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
import 'package:transito/widgets/liquid_glass/native_tab_bar.dart';
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

    var materialNavigationBar = NavigationBar(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shadowColor: Theme.of(context).colorScheme.shadow,
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

    var liquidGlassTabBar = NativeTabBar(
      tabs: [
        NativeTabBarItem(label: 'Nearby', symbol: 'safari.fill'),
        NativeTabBarItem(label: 'Favourites', symbol: 'heart.fill'),
        NativeTabBarItem(label: 'Search', symbol: 'map.fill'),
      ],
      actionButton: TabBarActionButton(
          symbol: _pageIndex == 0
              ? 'arrow.clockwise'
              : _pageIndex == 1
                  ? 'square.and.pencil'
                  : _pageIndex == 2
                      ? isUserCenter
                          ? 'location.fill'
                          : 'location'
                      : 'circle',
          onTap: () {
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
          }),
      currentIndex: _pageIndex,
      tintColor: Theme.of(context).colorScheme.primary,
      onTap: (index) {
        setState(() {
          _pageIndex = index;
        });
      },
    );

    return Scaffold(
		extendBody: true,
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
        ),
      ),
      bottomNavigationBar: Platform.isIOS && supportsLiquidGlass ? liquidGlassTabBar : materialNavigationBar,
    );
  }
}
