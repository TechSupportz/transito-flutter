import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_skeleton_ui/flutter_skeleton_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:form_builder_validators/localization/l10n.dart';
import 'package:is_first_run/is_first_run.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/common_provider.dart';
import 'package:transito/global/providers/favourites_provider.dart';
import 'package:transito/global/providers/search_provider.dart';
import 'package:transito/global/services/location_service.dart';
import 'package:transito/global/services/settings_service.dart';
import 'package:transito/global/services/transito_api_service.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/models/enums/app_theme_mode_enum.dart';
import 'package:transito/models/user/user_settings.dart';
import 'package:transito/screens/auth/login_screen.dart';
import 'package:transito/screens/navigator_screen.dart';
import 'package:transito/screens/onboarding/location_access_screen.dart';

import 'firebase_options.dart';

void main() async {
  Widget defaultHome = const LocationAccessScreen();

  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  bool isFirstRun = await IsFirstRun.isFirstRun();
  bool hasLocationPermission = await LocationService().hasLocationPermission();
  if (!isFirstRun && hasLocationPermission) {
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
  final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final svgsPaths = assetManifest.listAssets().where(
    (String key) => key.startsWith('assets/images/') && key.endsWith('.svg'),
  );

  for (var svgPath in svgsPaths) {
    var loader = SvgAssetLoader(svgPath);
    await svg.cache.putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
  }

  runApp(
    MultiProvider(
      providers: [
        StreamProvider<User?>.value(value: FirebaseAuth.instance.userChanges(), initialData: null),
        ChangeNotifierProvider(create: (context) => AppColors(), lazy: false),
        ChangeNotifierProvider(
          create: (context) => CommonProvider()..checkSupportsLiquidGlass(),
          lazy: false,
        ),
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
  @override
  Widget build(BuildContext context) {
    User? user = context.watch<User?>();

    bool isTablet = context.read<CommonProvider>().isTablet;
    bool isLoggedIn =
        (user != null && user.emailVerified == true) || (user != null && user.isAnonymous == true);

    AppColors appColors = context.watch<AppColors>();

    SettingsService().streamSettings(user?.uid).listen((UserSettings userSettings) {
      Brightness brightness = userSettings.themeMode == AppThemeMode.DARK
          ? Brightness.dark
          : userSettings.themeMode == AppThemeMode.LIGHT
          ? Brightness.light
          : MediaQuery.platformBrightnessOf(context);
      Color seedColor = Color(int.parse(userSettings.accentColour));

      if (seedColor != appColors.accentColour || brightness != appColors.brightness) {
        appColors.updateLocalColorScheme(seedColor, brightness);
      }

      TransitoApiService().updateUsingBetaServer(userSettings.betaServer.isUsingBetaServer);
    });

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Theme.of(context).colorScheme.primary.withAlpha(0),
      ),
    );

    return StreamBuilder<UserSettings>(
      stream: SettingsService().streamSettings(user?.uid),
      builder: (context, snapshot) {
        return SkeletonTheme(
          darkShimmerGradient: LinearGradient(
            colors: [
              appColors.scheme.surfaceContainerLow,
              appColors.scheme.surfaceContainerHigh,
              appColors.scheme.surfaceContainerLow,
            ],
          ),
          shimmerGradient: LinearGradient(
            colors: [
              appColors.scheme.surfaceContainerLow,
              appColors.scheme.surfaceContainerHigh,
              appColors.scheme.surfaceContainerLow,
            ],
          ),
          child: MaterialApp(
            title: "Transito",
            supportedLocales: const [Locale('en', 'US')],
            scaffoldMessengerKey: CommonProvider.scaffoldMessengerKey,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              FormBuilderLocalizations.delegate,
            ],
            navigatorObservers: kDebugMode ? [] : [PosthogObserver()],
            theme: ThemeData(
              fontFamily: "DMSans",
              textTheme: const TextTheme(
                displayLarge: TextStyle(letterSpacing: -0.5),
                displayMedium: TextStyle(letterSpacing: -0.5),
                displaySmall: TextStyle(letterSpacing: -0.5),
                headlineLarge: TextStyle(letterSpacing: -0.5),
                headlineMedium: TextStyle(letterSpacing: -0.5),
                headlineSmall: TextStyle(letterSpacing: -0.5),
                titleLarge: TextStyle(letterSpacing: -0.5),
                titleMedium: TextStyle(letterSpacing: -0.5),
                titleSmall: TextStyle(letterSpacing: -0.5),
                bodyLarge: TextStyle(letterSpacing: -0.5),
                bodyMedium: TextStyle(letterSpacing: -0.5),
                bodySmall: TextStyle(letterSpacing: -0.5),
                labelLarge: TextStyle(letterSpacing: -0.5),
                labelMedium: TextStyle(letterSpacing: -0.5),
                labelSmall: TextStyle(letterSpacing: -0.5),
              ),
              colorScheme: appColors.scheme,
              splashFactory: InkSparkle.splashFactory,
              tooltipTheme: TooltipThemeData(
                textStyle: TextStyle(
                  color: appColors.scheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                decoration: BoxDecoration(
                  color: appColors.scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              appBarTheme: AppBarTheme(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ), //NOTE - This is a workaround to make tint elevation animate.
                shadowColor: appColors.scheme.shadow.withValues(alpha: 0.2),
                toolbarHeight: 72
              ),
              checkboxTheme: CheckboxThemeData(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              textButtonTheme: TextButtonThemeData(
                style: ButtonStyle(
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.25),
                  ),
                ),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: ButtonStyle(
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.25),
                  ),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ButtonStyle(
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.25),
                  ),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: ButtonStyle(
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.25),
                  ),
                ),
              ),
              dialogTheme: DialogThemeData(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                titleTextStyle: TextStyle(
                  color: appColors.scheme.onSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: 24,
                  letterSpacing: -0.5,
                ),
              ),
              snackBarTheme: SnackBarThemeData(
                //FIXME - Animation is non-existant
                backgroundColor: appColors.scheme.surfaceContainerHighest,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                contentTextStyle: TextStyle(
                  color: appColors.scheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(width: 1.75),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                floatingLabelStyle: TextStyle(fontWeight: FontWeight.w600),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
              ),
            ),
            home: isLoggedIn ? widget.defaultHome : const LoginScreen(),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: isTablet ? const TextScaler.linear(1.25) : TextScaler.noScaling,
                ),
                child: SafeArea(top: false, bottom: false, child: child!),
              );
            },
          ),
        );
      },
    );
  }
}
