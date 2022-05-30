import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:transito/screens/navbar_screens/main_screen.dart';

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
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        scaffoldBackgroundColor: Color(0xFF0C0C0C),
        colorScheme: const ColorScheme.dark().copyWith(
          surface: Colors.black,
          primary: const Color(0xFF7E6BFF),
          secondary: const Color(0xFF7E6BFF),
        ),
      ),
      initialRoute: MainScreen.routeName,
      routes: {
        MainScreen.routeName: (context) => MainScreen(),
      },
    );
  }
}
