import 'package:flutter/material.dart';
import 'package:transito/models/app_colors.dart';
import 'package:transito/screens/navbar_screens/main_screen.dart';

import 'screens/bus_timing_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Transito",
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Color(0xFF0C0C0C),
        colorScheme: const ColorScheme.dark().copyWith(
          surface: Colors.black,
          primary: AppColors.veryPurple,
          secondary: AppColors.veryPurple,
        ),
      ),
      initialRoute: MainScreen.routeName,
      routes: {
        MainScreen.routeName: (context) => MainScreen(),
        BusTimingScreen.routeName: (context) => BusTimingScreen()
      },
      builder: (context, child) {
        return MediaQuery(
          child: child!,
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
        );
      },
    );
  }
}
