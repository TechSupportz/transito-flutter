import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController textFieldController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text("This is the search screen"),
            // TextField(
            //   controller: textFieldController,
            //   textAlign: TextAlign.center,
            //   keyboardType: TextInputType.number,
            // ),
            // SizedBox(
            //   height: 10,
            // ),
            // ElevatedButton(
            //   onPressed: () {
            //     _goToBusTimingScreen(context);
            //   },
            //   child: Text('Go to Bus Timing Page'),
            // )
          ],
        ),
      ),
    );
  }
}
