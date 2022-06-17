// ignore_for_file: prefer_const_constructors

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:parent_child_checkbox/parent_child_checkbox.dart';

import '../models/app_colors.dart';

class AddFavouritesScreen extends StatefulWidget {
  const AddFavouritesScreen({Key? key}) : super(key: key);

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
                  "Bus Stop Name",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        margin: EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                            color: AppColors.veryPurple, borderRadius: BorderRadius.circular(5)),
                        child: Text("75231", style: TextStyle(fontSize: 16))),
                    Text(
                      "Bus Stop Address",
                      style: TextStyle(
                          fontSize: 16, color: AppColors.kindaGrey, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                SizedBox(
                  height: 16,
                ),
                Text(
                  "Select all the bus services you would like to add to your favourites in this bus stop",
                  style: TextStyle(fontSize: 16, color: AppColors.kindaGrey),
                ),
                SizedBox(
                  height: 16,
                ),
                ParentChildCheckbox(
                  parent: Text("Bus Services", style: checkBoxFontStyle),
                  children: const [
                    Text("Service 1", style: checkBoxFontStyle),
                    Text("Service 2", style: checkBoxFontStyle),
                    Text("Service 3", style: checkBoxFontStyle),
                    Text("Service 4", style: checkBoxFontStyle),
                    Text("Service 5", style: checkBoxFontStyle),
                  ],
                  parentCheckboxColor: AppColors.veryPurple,
                  childrenCheckboxColor: AppColors.veryPurple,
                  parentCheckboxScale: 1.35,
                  childrenCheckboxScale: 1.35,
                  gap: 2,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConstrainedBox(
                      constraints: BoxConstraints(minHeight: 42),
                      child: ElevatedButton(
                          onPressed: () => print('bruh'), child: Text("Add to favourites"))),
                  SizedBox(
                    height: 8,
                  ),
                  ConstrainedBox(
                      constraints: BoxConstraints(minHeight: 42),
                      child: OutlinedButton(onPressed: () => print('bruh'), child: Text('Cancel')))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
