import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:form_builder_validators/localization/l10n.dart';
import 'package:geolocator/geolocator.dart';
import 'package:is_first_run/is_first_run.dart';
import 'package:provider/provider.dart';
import 'package:transito/models/app_colors.dart';
import 'package:transito/providers/authentication_service.dart';
import 'package:transito/providers/favourites_provider.dart';
import 'package:transito/providers/search_provider.dart';
import 'package:transito/screens/auth/login-screen.dart';
import 'package:transito/screens/navbar_screens/main_screen.dart';
import 'package:transito/screens/onboarding_screens/location_access_screen.dart';

import 'firebase_options.dart';

void main() async {
  Widget _defaultHome = LocationAccessScreen();

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  bool _isFirstRun = await IsFirstRun.isFirstRun();
  LocationPermission _permission = await Geolocator.checkPermission();
  if (!_isFirstRun && _permission == LocationPermission.always ||
      _permission == LocationPermission.whileInUse) {
    _defaultHome = MainScreen();
  }

  Future.wait([
    precachePicture(
      ExactAssetPicture(SvgPicture.svgStringDecoderBuilder, 'assets/images/logo.svg'),
      null,
    ),
    precachePicture(
      ExactAssetPicture(SvgPicture.svgStringDecoderBuilder, 'assets/images/google_logo.svg'),
      null,
    ),
    precachePicture(
      ExactAssetPicture(SvgPicture.svgStringDecoderBuilder, 'assets/images/location.svg'),
      null,
    ),
    precachePicture(
      ExactAssetPicture(SvgPicture.svgStringDecoderBuilder, 'assets/images/diagram.svg'),
      null,
    ),
  ]);

  runApp(
    MultiProvider(
      providers: [
        StreamProvider(
          create: (context) => AuthenticationService().authStateChanges,
          initialData: null,
        ),
        ChangeNotifierProvider(create: (context) => FavouritesProvider()),
        ChangeNotifierProvider(create: (context) => SearchProvider()),
      ],
      child: MyApp(defaultHome: _defaultHome),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key, required this.defaultHome}) : super(key: key);
  final Widget defaultHome;

  @override
  Widget build(BuildContext context) {
    var user = context.watch<User?>();
    bool isLoggedIn = user != null;

    return MaterialApp(
      title: "Transito",
      supportedLocales: const [Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FormBuilderLocalizations.delegate,
      ],
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
              minimumSize: const Size(15, 42)),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7.5),
            ),
            side: const BorderSide(color: AppColors.veryPurple),
            minimumSize: const Size(15, 42),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7.5),
            ),
          ),
        ),
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: AppColors.cardBg,
        ),
        tabBarTheme: const TabBarTheme(
          labelColor: AppColors.veryPurple,
          unselectedLabelColor: AppColors.kindaGrey,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.cardBg,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentTextStyle: const TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white,
          ),
          actionTextColor: AppColors.veryPurple,
        ),
        dividerColor: const Color(0xFF343434),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.kindaGrey,
                width: 2,
              )),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                width: 2,
                color: AppColors.cardBg,
              )),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          fillColor: AppColors.inputFieldBg,
          filled: true,
        ),
      ),
      home: isLoggedIn ? defaultHome : const LoginScreen(),
      builder: (context, child) {
        return MediaQuery(
          child: child!,
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
        );
      },
    );
  }
}
