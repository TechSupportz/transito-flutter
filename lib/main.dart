import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transito/models/app_colors.dart';
import 'package:transito/providers/favourites_provider.dart';
import 'package:transito/screens/navbar_screens/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => FavouritesProvider()),
      ],
      child: MaterialApp(
        title: "Transito",
        theme: ThemeData(
          fontFamily: 'Poppins',
          scaffoldBackgroundColor: Color(0xFF0C0C0C),
          colorScheme: const ColorScheme.dark().copyWith(
            surface: Colors.black,
            primary: AppColors.veryPurple,
            secondary: AppColors.veryPurple,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
          ),
          splashFactory: InkSplash.splashFactory,
          tooltipTheme: TooltipThemeData(
            textStyle: const TextStyle(
              color: AppColors.kindaGrey,
              fontWeight: FontWeight.w500,
            ),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          checkboxTheme: CheckboxThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            visualDensity: VisualDensity.standard,
            side: BorderSide(
              color: AppColors.kindaGrey,
              width: 1.75,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7.5),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7.5),
              ),
              side: BorderSide(color: AppColors.veryPurple),
            ),
          ),
        ),
        initialRoute: MainScreen.routeName,
        routes: {
          MainScreen.routeName: (context) => MainScreen(),
        },
        builder: (context, child) {
          return MediaQuery(
            child: child!,
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          );
        },
      ),
    );
  }
}
