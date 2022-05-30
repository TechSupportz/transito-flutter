import 'package:flutter/material.dart';
import 'package:transito/screens/navbar_screens/favourites_screen.dart';
import 'package:transito/screens/navbar_screens/home_screen.dart';
import 'package:transito/screens/navbar_screens/search_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);
  static String routeName = '/';

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int PageIndex = 0;
  final controller = PageController(
    initialPage: 0,
    keepPage: true,
  );
  List<StatefulWidget> widgetList = [
    HomeScreen(),
    FavouritesScreen(),
    SearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widgetList[PageIndex].toString().split("Screen")[0])),
      body: PageView(
        controller: controller,
        children: widgetList,
        onPageChanged: (index) {
          updatePageIndex(index);
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
        currentIndex: PageIndex,
        onTap: (index) {
          updatePageIndex(index);
        },
      ),
    );
  }

  void updatePageIndex(int index, {bool animate = true}) {
    setState(() {
      PageIndex = index;
      animate
          ? controller.animateToPage(index,
              duration: const Duration(milliseconds: 250), curve: Curves.ease)
          : controller.jumpToPage(index);
    });
  }
}
