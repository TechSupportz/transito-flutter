import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:transito/screens/bus_timing_screen.dart';

import '../../widgets/bus_stop_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void goToBusTimingScreen(String busStopCode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusTimingScreen(
          busStopCode: busStopCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Nearby",
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 12,
        ),
        Expanded(
          child: GridView.count(
            childAspectRatio: 2.5 / 1,
            crossAxisSpacing: 18,
            mainAxisSpacing: 21,
            shrinkWrap: true,
            crossAxisCount: 2,
            children: [
              BusStopCard(),
              BusStopCard(),
              BusStopCard(),
              BusStopCard(),
              BusStopCard(),
              BusStopCard(),
            ],
          ),
        )
      ],
    );
  }
}
