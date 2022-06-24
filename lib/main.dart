import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:is_first_run/is_first_run.dart';
import 'package:provider/provider.dart';
import 'package:transito/models/app_colors.dart';
import 'package:transito/providers/favourites_provider.dart';
import 'package:transito/providers/search_provider.dart';
import 'package:transito/screens/navbar_screens/main_screen.dart';
import 'package:transito/screens/onboarding_screens/location_access_screen.dart';

void main() async {
  Widget _defaultHome = LocationAccessScreen();

  WidgetsFlutterBinding.ensureInitialized();
  bool _isFirstRun = await IsFirstRun.isFirstRun();
  LocationPermission _permission = await Geolocator.checkPermission();
  if (!_isFirstRun && _permission == LocationPermission.always ||
      _permission == LocationPermission.whileInUse) {
    _defaultHome = MainScreen();
  }

  runApp(MyApp(defaultHome: _defaultHome));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key, required this.defaultHome}) : super(key: key);

  final Widget defaultHome;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => FavouritesProvider()),
        ChangeNotifierProvider(create: (context) => SearchProvider()),
      ],
      child: MaterialApp(
        title: "Transito",
        theme: ThemeData(
          fontFamily: 'Poppins',
          canvasColor: Colors.transparent,
          androidOverscrollIndicator: AndroidOverscrollIndicator.stretch,
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
            side: const BorderSide(
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
              side: const BorderSide(color: AppColors.veryPurple),
            ),
          ),
          dialogTheme: DialogTheme(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          tabBarTheme: const TabBarTheme(
            labelColor: AppColors.veryPurple,
            unselectedLabelColor: AppColors.kindaGrey,
          ),
        ),
        home: defaultHome,
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
