# AGENTS.md - Transito Flutter

Guidelines for AI coding agents working on this Flutter bus timing application.

## Build & Development Commands

```bash
# Check Flutter version (uses FVM)
flutter --version

# Development server (DO NOT RUN - use transito-dev alias instead)
# The user has a fish alias `transito-dev` that starts Firebase emulators + Flutter in tmux
# ALWAYS ask the user: "Is transito-dev running?" before making changes that need hot reload

# Code generation (for JSON models)
flutter pub run build_runner build

# Linting
flutter analyze

# Testing (no test/ directory currently exists in this project)
flutter test
flutter test test/widget_test.dart  # Run single test file once tests are added

# Building
flutter build apk
flutter build ios
```

**IMPORTANT:** Never run Shorebird commands (`shorebird release`, `shorebird patch`). These are always run by the user.

**IMPORTANT:** After editing ANY Dart file, you MUST format it with the repo formatter config:
```bash
dart format <file>
```
The formatter contract lives in `analysis_options.yaml` (`formatter.page_width: 100`,
`trailing_commas: preserve`) and `.vscode/settings.json` mirrors it for VS Code. Do not manually
format checked-in `.g.dart` files; regenerate them with `flutter pub run build_runner build`.

## Code Style Guidelines

### General
- Follow `package:flutter_lints/flutter.yaml` rules
- Use 2-space indentation
- Prefer single quotes for strings
- Use `super.key` in widget constructors
- Explicit types preferred over `var`/`dynamic`

### Imports Order
1. Dart SDK imports (`dart:async`, `dart:convert`, etc.)
2. Flutter imports (`package:flutter/material.dart`)
3. Third-party packages (alphabetical)
4. Project imports (`package:transito/...`)
5. Relative imports (within same directory)

### Naming Conventions
- **Files**: `snake_case.dart` (e.g., `bus_stop_card.dart`)
- **Classes**: `PascalCase` (e.g., `BusStop`, `NearbyScreen`)
- **Variables/Functions**: `camelCase` (e.g., `nearbyBusStops`, `refresh()`)
- **Private members**: `_camelCase` with underscore prefix
- **Constants**: `camelCase` or `PascalCase` for enum values
- **Enums**: `PascalCase` for name, `SCREAMING_SNAKE_CASE` for values

### Architecture Patterns

**State Management**: Provider pattern with ChangeNotifier
```dart
class MyProvider extends ChangeNotifier {
  void update() => notifyListeners();
}
```

**Models**: Use `json_serializable` with `explicitToJson: true`
```dart
@JsonSerializable(explicitToJson: true)
class Model {
  factory Model.fromJson(Map<String, dynamic> json) => _$ModelFromJson(json);
  Map<String, dynamic> toJson() => _$ModelToJson(this);
}
```

**Screens**: StatefulWidget with Controller pattern for parent communication
```dart
class ScreenController extends ChangeNotifier {
  void action() => notifyListeners();
}

class MyScreen extends StatefulWidget {
  final MyScreenController? controller;
}
```

**API Services**: Singleton pattern extending `BaseApiService`
```dart
class MyApiService extends BaseApiService {
  MyApiService._internal();
  static final MyApiService _instance = MyApiService._internal();
  factory MyApiService() => _instance;
}
```

**Global UI Access**: Use `CommonProvider.scaffoldMessengerKey` to show snackbars from services without a BuildContext:
```dart
CommonProvider.scaffoldMessengerKey.currentState?.showSnackBar(...);
```

### Error Handling
- Use `try-catch` for async operations
- Use `debugPrint()` for debug logging (not `print`)
- Check `kDebugMode` before debug-only code

### UI Guidelines
- Use Material 3 design system
- Custom font: DM Sans (primary), Itim (secondary)
- Use `AppSymbol` widget instead of direct Icon for Material Symbols
- Support both Material and iOS-style navigation (Liquid Glass)
- Use `Theme.of(context).colorScheme` for colors

## Project Structure

**Note:** This section should be updated whenever new folders or files are added to the project to always reflect the most current state.

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── global/
│   ├── providers/           # ChangeNotifier providers
│   ├── services/            # Business logic services
│   └── utils/               # Utility functions
├── models/
│   ├── api/
│   │   ├── lta/             # LTA API response models
│   │   └── transito/        # Transito backend API models
│   │       └── onemap/      # OneMap search models
│   ├── app/                 # App-level models (colors, settings)
│   ├── enums/               # Enum definitions
│   ├── favourites/          # Favourite-related models
│   ├── user/                # User-related models
│   └── secret.dart          # API keys and secrets
├── screens/
│   ├── navigator_screen.dart # Root adaptive navigation screen
│   ├── auth/                # Authentication screens
│   ├── bus_info/            # Bus information screens
│   ├── favourites/          # Favourites screens
│   ├── main/                # Main app screens (nearby, MRT map, settings)
│   ├── onboarding/          # First-time user screens
│   └── search/              # Search/map screens
└── widgets/
    ├── auth/
    ├── bus_info/
    ├── bus_timings/
    ├── common/              # Shared widgets (AppSymbol, etc.)
    ├── favourites/
    ├── liquid_glass/        # iOS-specific glass effects
    ├── search/
    └── settings/
```

## Key Dependencies

- **State**: `provider`, `ChangeNotifier`
- **Firebase**: `firebase_core`, `firebase_auth`, `cloud_firestore`
- **Maps**: `flutter_map`, `flutter_map_animations`, `flutter_map_location_marker`, `flutter_map_marker_cluster`, `latlong2`
- **Network**: `http`
- **Location**: `geolocator`
- **Auth**: `google_sign_in`, `sign_in_with_apple`
- **Serialization**: `json_annotation`, `json_serializable`
- **Storage & Settings**: `shared_preferences`, `package_info_plus`
- **Analytics & Updates**: `posthog_flutter`, `upgrader`
- **UI**: `animations`, `cupertino_icons`, `flutter_colorpicker`, `flutter_form_builder`, `flutter_skeleton_ui`, `flutter_svg`, `form_builder_validators`, `material_symbols_icons`, `native_glass_navbar`, `photo_view`, `smooth_highlight`
- **Utilities**: `alphanum_comparator`, `collection`, `google_polyline_algorithm`, `jiffy`, `measure_size`, `url_launcher`

## Development Notes

- Firebase emulators run on ports 9099 (auth) and 8088 (firestore)
- Backend API (Node.js/Koa) runs on localhost port 8080
- Use Shorebird for over-the-air updates (user runs these commands)
- No `test/` directory exists yet - add tests there when needed
- Assets located in `assets/` (images, icons, fonts)
- Supports both phone and tablet layouts (isTablet check in CommonProvider)
- FVM manages Flutter version (3.41.0) - commands work without `fvm` prefix in this project
- API exceptions are defined in `lib/global/services/api_exceptions.dart` (`ApiException`, `NetworkException`, `ApiParsingException`)
- `pubspec.yaml` defines a `dev` script, but agents should still use the user's `transito-dev` alias instead of running it directly

## Common Patterns

### LTA API Failure Handling
Use `showLtaMaintenanceWarningSnackbar()` to alert users when LTA API calls fail:
```dart
try {
  final info = await LtaApiService().getBusArrival(busStopCode);
} catch (error) {
  showLtaMaintenanceWarningSnackbar();
  rethrow;
}
```

### FutureBuilder Error Display
Use the `ErrorText` widget for consistent error UI in FutureBuilders:
```dart
if (snapshot.hasError) {
  return const ErrorText();
}
```
