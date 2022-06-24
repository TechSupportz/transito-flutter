import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:transito/screens/navbar_screens/favourites_screen.dart';
import 'package:transito/screens/navbar_screens/home_screen.dart';
import 'package:transito/screens/navbar_screens/recent_search_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _pageIndex = 0;
  final controller = PageController(
    initialPage: 0,
    keepPage: true,
  );

  List<StatefulWidget> widgetList = const [
    HomeScreen(),
    FavouritesScreen(),
    RecentSearchScreen(),
  ];

  void updatePageIndex(int index, {bool animate = true}) {
    debugPrint('$index');
    setState(() {
      _pageIndex = index;
      animate
          ? controller.animateToPage(index,
              duration: const Duration(milliseconds: 250), curve: Curves.ease)
          : controller.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: controller,
        children: widgetList,
        pageSnapping: true,
        dragStartBehavior: DragStartBehavior.start,
        onPageChanged: (index) {
          setState(() => _pageIndex = index);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: "Favourites"),
          BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: "Search"),
        ],
        backgroundColor: Colors.black,
        unselectedItemColor: Color(0xFFD8DBE2),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _pageIndex,
        onTap: (index) {
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
