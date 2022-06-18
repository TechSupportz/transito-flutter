import 'package:flutter/material.dart';
import 'package:parent_child_checkbox/parent_child_checkbox.dart';

import '../models/app_colors.dart';

class AddFavouritesScreen extends StatefulWidget {
  const AddFavouritesScreen(
      {Key? key,
      required this.busStopCode,
      required this.busStopName,
      required this.busStopAddress,
      required this.busServicesList})
      : super(key: key);
  final String busStopCode;
  final String busStopName;
  final String busStopAddress;
  final List<String> busServicesList;

  @override
  State<AddFavouritesScreen> createState() => _AddFavouritesScreenState();
}

const checkBoxFontStyle = TextStyle(
  fontSize: 24,
);

class _AddFavouritesScreenState extends State<AddFavouritesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add to Favourites'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.busStopName,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                            color: AppColors.veryPurple, borderRadius: BorderRadius.circular(5)),
                        child: Text(widget.busStopCode, style: const TextStyle(fontSize: 16))),
                    Text(
                      widget.busStopAddress,
                      style: const TextStyle(
                          fontSize: 16, color: AppColors.kindaGrey, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 16,
                ),
                const Text(
                  "Select all the bus services you would like to add to your favourites in this bus stop",
                  style: TextStyle(fontSize: 16, color: AppColors.kindaGrey),
                ),
                const SizedBox(
                  height: 16,
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ParentChildCheckbox(
                      parent: const Text("Bus Services", style: checkBoxFontStyle),
                      children: [
                        for (var service in widget.busServicesList)
                          Text(service, style: checkBoxFontStyle),
                      ],
                      parentCheckboxColor: AppColors.veryPurple,
                      childrenCheckboxColor: AppColors.veryPurple,
                      parentCheckboxScale: 1.35,
                      childrenCheckboxScale: 1.35,
                      gap: 2,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 42),
                      child: ElevatedButton(
                          onPressed: () => print('bruh'), child: const Text("Add to favourites"))),
                  const SizedBox(
                    height: 8,
                  ),
                  ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 42),
                      child: OutlinedButton(
                          onPressed: () => print('bruh'), child: const Text('Cancel')))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
