# AGENTS.md - Transito Flutter

Transito is a Flutter bus timing application for Singapore. Use this file as the repository map and
source of project-specific constraints; inspect nearby code and configuration for ordinary Dart and
Flutter conventions.

## Non-negotiable constraints

- Never run Shorebird commands (`shorebird release`, `shorebird patch`). The user always runs them.
- Do not start the development stack directly or run the `dev` script. The user starts it with the
  fish alias `transito-dev`.
- Before asking the user to run `transito-dev`, check that both port 8080 (Transito server) and port
  4000 (Firebase emulator UI) are listening:
  `lsof -nP -iTCP:8080 -sTCP:LISTEN` and `lsof -nP -iTCP:4000 -sTCP:LISTEN`.
- After editing any non-generated Dart file, run `dart format <file>`.
- Do not manually edit or format checked-in `.g.dart` files. Regenerate them with
  `flutter pub run build_runner build`.

## Commands and verification

```bash
flutter --version                         # Flutter 3.41.0 managed by FVM
flutter pub run build_runner build        # Regenerate JSON serialization code
flutter analyze                           # Static analysis
flutter test                              # Logic-heavy test suite
flutter test test/specific_test.dart      # Relevant logic-heavy test
flutter build apk                         # Android build when requested/needed
flutter build ios                         # iOS build when requested/needed
```

- The formatter contract is defined in `analysis_options.yaml` (`page_width: 100`,
  `trailing_commas: preserve`). `.vscode/settings.json` mirrors it for VS Code.
- Run formatting and static analysis after normal Dart changes. Run code generation when annotated
  models change.
- Do not add unit or widget tests by default for routine UI, model, persistence, or serialization
  changes. Add or update tests for substantial data processing, complex algorithms, or a regression
  best protected by a focused test.
- For normal UI work, prefer widget previews, hot reload, formatting, and static analysis.

## Architecture map

- `lib/global/providers/`: shared `ChangeNotifier` state.
- `lib/global/services/`: API clients and shared business services.
- `lib/global/utils/`: shared utilities.
- `lib/models/`: API, app, favourites, user, and enum models.
- `lib/screens/`: application screens grouped by feature.
- `lib/widgets/`: reusable widgets grouped by feature; shared widgets live in `widgets/common/`.
- `docs/adr/`: architecture decision records.
- `tool/`: local development utilities.

State management uses Provider with `ChangeNotifier`. API services extend `BaseApiService` and use
the repository's singleton pattern. JSON API models use `json_serializable` with
`@JsonSerializable(explicitToJson: true)` where nested objects must be serialized explicitly.

Use a screen `ChangeNotifier` controller when a parent needs imperative control of the screen. Do
not introduce a controller or abstraction that merely delegates to an already available dependency;
an abstraction should add behavior, enforce a boundary, or meaningfully improve reuse.

## Project-specific conventions

- Use `AppSymbol` instead of a direct `Icon` for Material Symbols.
- Preserve both Material and iOS-style Liquid Glass navigation behavior.
- Use DM Sans as the primary font and Itim as the secondary font.
- Use `CommonProvider.scaffoldMessengerKey` when a service needs to show a snackbar without a
  `BuildContext`.
- Catch async errors where the code adds recovery, translation, logging, or user feedback. Otherwise
  allow errors to propagate.
- Use `debugPrint()` for debug logging and guard debug-only behavior with `kDebugMode`.
- Existing API/wire enum values in `lib/models/enums/` use uppercase names. Internal Dart-only enums
  may follow the local surrounding convention.
- Use `Theme.of(context).colorScheme` rather than introducing hard-coded theme colors.

## Error handling and UI states

- API exceptions are defined in `lib/global/services/api_exceptions.dart` (`ApiException`,
  `NetworkException`, and `ApiParsingException`).
- When an LTA API call fails in a flow that needs maintenance feedback, preserve the established
  `showLtaMaintenanceWarningSnackbar()` behavior.
- Use `ErrorText` for consistent error presentation in `FutureBuilder` and equivalent async states.

## Canonical examples

- API singleton and LTA failure handling: `lib/global/services/lta_api_service.dart`
- Backend API service: `lib/global/services/transito_api_service.dart`
- Screen controller: `lib/screens/main/nearby_screen.dart`
- Global snackbar access: `lib/widgets/common/lta_maintenance_warning_snackbar.dart`
- Shared async error UI: `lib/widgets/common/error_text.dart`
- Shared app state and device layout information: `lib/global/providers/common_provider.dart`

## Local environment

- Firebase emulators use ports 9099 (Auth), 8088 (Firestore), and 4000 (Emulator UI).
- The Node.js/Koa backend uses localhost port 8080.
- Assets live in `assets/`.
- The application supports phone and tablet layouts; shared device state is exposed by
  `CommonProvider`.
