import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import "package:native_glass_navbar/native_glass_navbar.dart";
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
  final List<ValueNotifier<bool>> _pageActivity = List<ValueNotifier<bool>>.generate(
    3,
    (_) => ValueNotifier<bool>(false),
  );

  late final List<Widget?> _pages;

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.initialPageIndex;
    _pageActivity[_pageIndex].value = true;

    _pages = <Widget?>[
      _createPage(0),
      null,
      _createPage(2),
    ];
    if (_pageIndex == 1) {
      _pages[1] = _createPage(1);
    }
  }

  Widget _createPage(int index) {
    return switch (index) {
      0 => NearbyScreen(
        controller: _nearbyScreenController,
        isActive: _pageActivity[0],
      ),
      1 => FavouritesScreen(
        controller: _favouritesScreenController,
        isActive: _pageActivity[1],
      ),
      2 => MapSearchScreen(controller: _mapSearchScreenController),
      _ => throw RangeError.index(index, _pages),
    };
  }

  void _selectPage(int index) {
    if (index == _pageIndex) return;

    setState(() {
      _pages[index] ??= _createPage(index);
      _pageIndex = index;
    });

    for (int page = 0; page < _pageActivity.length; page++) {
      _pageActivity[page].value = page == index;
    }
  }

  List<Widget> get _mountedPages => List<Widget>.generate(
    _pages.length,
    (int index) => _pages[index] ?? SizedBox.shrink(key: ValueKey<String>('unmounted-page-$index')),
  );

  @override
  void dispose() {
    for (final ValueNotifier<bool> activity in _pageActivity) {
      activity.dispose();
    }
    super.dispose();
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
          icon: AppSymbol(Symbols.explore_rounded, fill: true),
          label: "Nearby",
        ),
        NavigationDestination(
          icon: AppSymbol(Symbols.favorite_rounded, fill: true),
          label: "Favourites",
        ),
        NavigationDestination(
          icon: GestureDetector(
            child: AppSymbol(Symbols.map_search_rounded, fill: true),
            onTap: () => _selectPage(2),
            onDoubleTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MrtMapScreen(),
                settings: RouteSettings(name: 'MrtMapScreen'),
              ),
            ),
          ),
          label: "Search",
        ),
      ],
      selectedIndex: _pageIndex,
      height: 72,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      // updates _pageIndex and animates the page transition
      onDestinationSelected: _selectPage,
    );

    var nativeGlassNavBar = NativeGlassNavBar(
      tabs: [
        NativeGlassNavBarItem(label: 'Nearby', symbol: 'safari.fill'),
        NativeGlassNavBarItem(label: 'Favourites', symbol: 'heart.fill'),
        NativeGlassNavBarItem(label: 'Search', symbol: 'map.fill'),
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
        },
      ),
      currentIndex: _pageIndex,
      tintColor: Theme.of(context).colorScheme.primary,
      fallback:
          materialNavigationBar, // Fallback to material nav bar if liquid glass is not supported
      onTap: _selectPage,
    );

    return Scaffold(
      extendBody: supportsLiquidGlass ? true : false,
      body: UpgradeAlert(
        upgrader: Upgrader(
          countryCode: "SG",
        ),
        child: AnimatedIndexedStack(
          transitionBuilder:
              (
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
          children: _mountedPages,
        ),
      ),
      bottomNavigationBar: Platform.isIOS ? nativeGlassNavBar : materialNavigationBar,
    );
  }
}
