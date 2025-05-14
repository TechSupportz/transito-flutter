import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:form_builder_validators/localization/l10n.dart';
import 'package:geolocator/geolocator.dart';
import 'package:is_first_run/is_first_run.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:provider/provider.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/models/user/user_settings.dart';
import 'package:transito/global/providers/common_provider.dart';
import 'package:transito/global/providers/favourites_provider.dart';
import 'package:transito/global/providers/search_provider.dart';
import 'package:transito/global/services/settings_service.dart';
import 'package:transito/screens/auth/login_screen.dart';
import 'package:transito/screens/navigator_screen.dart';
import 'package:transito/screens/onboarding/location_access_screen.dart';
import 'package:transito/widgets/android_stretch_behaviour.dart';

import 'firebase_options.dart';

void main() async {
  Widget defaultHome = const LocationAccessScreen();

  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  bool isFirstRun = await IsFirstRun.isFirstRun();
  LocationPermission permission = await Geolocator.checkPermission();
  if (!isFirstRun && permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse) {
    defaultHome = const NavigatorScreen();
  }

  if (kDebugMode) {
    try {
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8088);
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      Posthog().debug(true);
      debugPrint("Connected to the firebase emulators");
    } on Exception catch (e) {
      debugPrint('Failed to connect to the emulators: $e');
    }
  }

  // load all svg assets
  final manifestJson = await rootBundle.loadString('AssetManifest.json');
  List svgsPaths = (json
              .decode(manifestJson)
              .keys
              .where((String key) => key.startsWith('assets/images/') && key.endsWith('.svg'))
          as Iterable)
      .toList();

  for (var svgPath in svgsPaths as List<String>) {
    var loader = SvgAssetLoader(svgPath);
    await svg.cache.putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
  }

  runApp(
    MultiProvider(
      providers: [
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.userChanges(),
          initialData: null,
        ),
        ChangeNotifierProvider(create: (context) => CommonProvider()),
        ChangeNotifierProvider(create: (context) => FavouritesProvider()),
        ChangeNotifierProvider(create: (context) => SearchProvider()),
      ],
      child: MyApp(defaultHome: defaultHome),
    ),
  );
  FlutterNativeSplash.remove();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.defaultHome});
  final Widget defaultHome;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Color primaryColour = AppColors.accentColour;

  @override
  Widget build(BuildContext context) {
    var user = context.watch<User?>();
    debugPrint("$user");

    bool isTablet = context.read<CommonProvider>().isTablet;
    bool isLoggedIn =
        (user != null && user.emailVerified == true) || (user != null && user.isAnonymous == true);

    return StreamBuilder<UserSettings>(
        stream: SettingsService().streamSettings(user?.uid),
        builder: (context, snapshot) {
          return MaterialApp(
            title: "Transito",
            supportedLocales: const [Locale('en', 'US')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              FormBuilderLocalizations.delegate,
            ],
            navigatorObservers: kDebugMode ? [] : [PosthogObserver()],
            theme: ThemeData(
              // useMaterial3: false,
              fontFamily: 'Poppins',
              canvasColor: Colors.transparent,
              // scaffoldBackgroundColor: const Color(0xFF0C0C0C),
              // cardColor: const Color(0xFF0C0C0C),
              colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColors.accentColour, brightness: Brightness.dark),
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
                  side: BorderSide(color: AppColors.accentColour),
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
                backgroundColor: AppColors.cardBg(context),
              ),
              tabBarTheme: TabBarTheme(
                labelColor: AppColors.accentColour,
                unselectedLabelColor: AppColors.kindaGrey,
              ),
              snackBarTheme: SnackBarThemeData(
                backgroundColor: const Color(0xFF262626),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentTextStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  color: AppColors.kindaGrey,
                ),
                actionTextColor: AppColors.accentColour,
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
                    borderSide: BorderSide(
                      width: 2,
                      color: AppColors.cardBg(context),
                    )),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                fillColor: AppColors.inputFieldBg,
                filled: true,
              ),
              iconTheme: isTablet
                  ? const IconThemeData(size: 30, color: AppColors.kindaGrey)
                  : const IconThemeData(
                      size: 24,
                      color: AppColors.kindaGrey,
                    ),
            ),
            home: isLoggedIn ? widget.defaultHome : const LoginScreen(),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: isTablet ? const TextScaler.linear(1.25) : TextScaler.noScaling),
                child: ScrollConfiguration(
                  behavior:
                      const AndroidStretchScrollBehavior(), //NOTE - This is a temporary solution till the app migrates to use Material 3
                  child: SafeArea(child: child!),
                ),
              );
            },
          );
        });
  }
}
