# AGENTS.md - Transito Flutter

Transito is a Flutter bus timing app for Singapore. Domain terms (Favourite, Favourite Alias, Crowd
Level, Service Route, ...) are defined in `CONTEXT.md`; use them in code, comments, and UI copy.

## Running the app and dev stack

- The dev stack (Transito server on 8080, Firebase emulators with the UI on 4000) runs in the tmux
  session `transito`. When a task needs it and `tmux has-session -t transito` fails, start it with
  `fish ~/Developer/Transito/dev-env.fish` (the user's `transito-dev` alias). Read a pane's logs
  with `tmux capture-pane -p -t transito:0.0` (server) or `transito:0.1` (emulators).
- `flutter run` is yours for development and hot reload. First check for an existing Flutter
  session on the target device and reuse it; start a new one only when none is running.
- Store releases and Shorebird patches ship to production users. Run one only when the user asks
  for it in the current task, and state the exact command first. A store release is
  `bundle exec fastlane release`: it needs approved notes in `fastlane/release_notes/<version>/`
  (the `release-notes` skill writes them) committed with the version bump, then analyzes, tests, builds both platforms with
  Shorebird, submits both for review, and tags the version. For `shorebird patch`, run
  `flutter analyze` and `flutter test` first.
- In T3 Code, do work that needs changes to `../transito-server` in a new thread in the
  `transito-server` project, with a self-contained brief, rather than editing the server from a
  Flutter thread.

## Verification

- Use the Flutter SDK pinned in `.fvmrc`.
- After editing a non-generated Dart file, run `dart format <file>`, then `flutter analyze`.
- `.g.dart` files are generated: change the annotated source and run
  `dart run build_runner build`.
- Add or update tests for substantial data processing, complex algorithms, or a regression best
  protected by a focused test. Routine UI, model, persistence, and serialization changes are
  verified with formatting, analysis, widget previews, and hot reload instead.
- For layout changes, check both phone and tablet layouts (device state lives in `CommonProvider`).
- For navigation changes, check both the Material and the iOS Liquid Glass paths
  (`CommonProvider.supportsLiquidGlass`).

## Architecture

- State is Provider with `ChangeNotifier`. When a parent needs imperative control of a screen, give
  the screen a `ChangeNotifier` controller, as in `lib/screens/main/nearby_screen.dart`. Add other
  abstractions only when they add behavior, enforce a boundary, or meaningfully improve reuse.
- HTTP services extend `BaseApiService` as singletons; follow
  `lib/global/services/lta_api_service.dart` and `lib/global/services/transito_api_service.dart`.
  Match the JSON annotations of adjacent models.
- Before changing Favourite aliases, favourite card expansion, timing row counts, Firestore user
  access, or bus distance, read the matching record in `docs/adr/`.

## Conventions

- Render Material Symbols with `AppSymbol`.
- Use the text styles in `lib/models/app/app_typography.dart` (DM Sans primary, Itim secondary).
- Use `Theme.of(context).colorScheme` for theme colors.
- Log with `debugPrint()`, and guard debug-only behavior with `kDebugMode`.
- Keep existing enum value names in `lib/models/enums/`, since they are serialized; new enums
  follow the surrounding convention.
- Services that need a snackbar without a `BuildContext` use `CommonProvider.scaffoldMessengerKey`.

## API errors and UI states

- Throw the types in `lib/global/services/api_exceptions.dart` (`ApiException`,
  `NetworkException`, `ApiParsingException`).
- Calls to LTA, NUS, and the Transito server report to `AlertsProvider` with `reportSuccess` after
  parsing succeeds and `reportFailure` on error, as `lta_api_service.dart` does. `AlertsProvider`
  decides what becomes an Outage in the Nearby alert inbox, so these calls surface failures there
  rather than through their own snackbars. Background:
  `../transito-server/docs/adr/0001-detect-outages-per-device.md`.
- Catch async errors only where the catch adds recovery, translation, logging, or user feedback.
- Show async error states (`FutureBuilder` and equivalents) with `ErrorText`.
