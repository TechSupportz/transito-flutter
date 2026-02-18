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

# Testing (no tests currently exist in this project)
flutter test
flutter test test/widget_test.dart  # Run single test file

# Building
flutter build apk
flutter build ios
```

**IMPORTANT:** Never run Shorebird commands (`shorebird release`, `shorebird patch`). These are always run by the user.

**IMPORTANT:** After editing ANY Dart file, you MUST format it with the line length parameter:
```bash
dart format --line-length=100 <file>
```

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
- Custom font: Poppins (primary), Itim (secondary)
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
│   │   └── transito/
│   │       └── onemap/      # OneMap-related models
│   ├── app/                 # App-level models (colors, settings)
│   ├── enums/               # Enum definitions
│   ├── favourites/          # Favourite-related models
│   ├── user/                # User-related models
│   └── secret.dart          # API keys and secrets
├── screens/
│   ├── auth/                # Authentication screens
│   ├── bus_info/            # Bus information screens
│   ├── favourites/          # Favourites screens
│   ├── main/                # Main app screens (nearby, settings)
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
- **Maps**: `flutter_map`, `latlong2`
- **Network**: `http`
- **Location**: `geolocator`
- **Auth**: `google_sign_in`, `sign_in_with_apple`
- **Serialization**: `json_annotation`, `json_serializable`
- **UI**: `animations`, `flutter_skeleton_ui`, `material_symbols_icons`

## Development Notes

- Firebase emulators run on ports 9099 (auth) and 8088 (firestore)
- Backend API (Node.js/Koa) runs on localhost port 8080
- Use Shorebird for over-the-air updates (user runs these commands)
- No automated tests exist yet - add to `test/` directory when needed
- Assets located in `assets/` (images, icons, fonts)
- Supports both phone and tablet layouts (isTablet check in CommonProvider)
- FVM manages Flutter version (3.35.7) - commands work without `fvm` prefix in this project
- API exceptions are defined in `lib/global/services/api_exceptions.dart` (`ApiException`, `NetworkException`, `ApiParsingException`)

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
