import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:transito/widgets/bus_timing_row.dart';

import '../modals/mock_data.dart';

class BusTimingScreen extends StatefulWidget {
  const BusTimingScreen({Key? key}) : super(key: key);
  static String routeName = '/BusTiming';

  @override
  State<BusTimingScreen> createState() => _BusTimingScreenState();
}

class _BusTimingScreenState extends State<BusTimingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bus stop name"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Wrap(children: [
          BusTimingRow(
            arrivalInfo: jsonDecode(mockTestingData.mockData),
          )
        ]),
      ),
    );
  }
}
