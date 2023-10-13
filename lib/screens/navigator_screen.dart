import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transito/providers/common_provider.dart';
import 'package:transito/screens/favourites/favourites_screen.dart';
import 'package:transito/screens/main/home_screen.dart';
import 'package:transito/screens/search/recent_search_screen.dart';
import 'package:upgrader/upgrader.dart';

class NavigatorScreen extends StatefulWidget {
  const NavigatorScreen({Key? key}) : super(key: key);

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
    HomeScreen(),
    FavouritesScreen(),
    RecentSearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    bool isTablet = context.read<CommonProvider>().isTablet;

    return Scaffold(
      body: UpgradeAlert(
        upgrader: Upgrader(
          countryCode: "SG",
        ),
        child: PageView(
          controller: controller,
          children: widgetList,
          pageSnapping: true,
          dragStartBehavior: DragStartBehavior.start,
          onPageChanged: (index) {
            setState(() => _pageIndex = index);
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: "Favourites"),
          BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: "Search"),
        ],
        iconSize: isTablet ? 32 : 24,
        backgroundColor: Colors.black,
        unselectedItemColor: const Color(0xFFD8DBE2),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _pageIndex,
        onTap: (index) {
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
