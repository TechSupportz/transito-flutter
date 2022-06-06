import 'package:flutter/material.dart';
import 'package:transito/screens/bus_timing_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController textFieldController = TextEditingController();

  void _goToBusTimingScreen(BuildContext context) {
    String _busStopCode = textFieldController.text;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusTimingScreen(
          busStopCode: _busStopCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("This is the search screen"),
          TextField(
            controller: textFieldController,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
          ),
          SizedBox(
            height: 10,
          ),
          ElevatedButton(
            onPressed: () {
              _goToBusTimingScreen(context);
            },
            child: Text('Go to Bus Timing Page'),
          )
        ],
      ),
    );
  }
}
