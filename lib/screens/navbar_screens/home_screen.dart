import 'package:flutter/material.dart';
import 'package:transito/screens/bus_timing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _homeScreenState();
}

class _homeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("This is the home screen"),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BusTimingScreen(),
                ),
              );
            },
            child: Text('Go to Bus Timing Page'),
          )
        ],
      ),
    );
  }
}
