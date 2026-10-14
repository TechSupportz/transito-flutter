# AGENTS.md - Transito Flutter

Transito is a Flutter bus timing app for Singapore. Explicit user instructions in the current
conversation take precedence over this file. Check `CONTEXT.md` for domain terms when changing
domain behavior, and the relevant `docs/adr/` records before architectural changes.

## Guardrails

- Do not run Shorebird commands (`shorebird release`, `shorebird patch`, `shorebird preview`) unless
  the user explicitly asks you to in the current conversation.
- Leave starting the background development stack (transito-server's `dev` script and the Firebase
  emulators) to the user, who runs the fish alias `transito-dev`. Before asking them to, check
  whether the Transito server (8080) and Firebase Emulator UI (4000) are already listening:
  `lsof -nP -iTCP:8080 -sTCP:LISTEN` and `lsof -nP -iTCP:4000 -sTCP:LISTEN`. Emulator ports are in
  `firebase.json`.
- Run `fvm flutter run` only after confirming no other Flutter build is running on the same target
  device.

## Commands and verification

The Flutter version is pinned by FVM in `.fvmrc`; build and release with that version. The global
`flutter` on PATH may differ, so prefix Flutter and Dart commands with `fvm`.

```bash
fvm dart format <file>                    # After editing any hand-written Dart file
fvm flutter analyze                       # After Dart changes
fvm dart run build_runner build           # After changing json_serializable models
fvm flutter test                          # Logic-heavy test suite
```

- Regenerate checked-in `.g.dart` files with `build_runner`; leave them out of manual edits and
  formatting.
- For routine UI work, prefer widget previews (`@Preview`) and hot reload over new tests. Add or
  update tests for substantial data processing, complex algorithms, or a regression best protected
  by a focused test.

## Architecture

- `lib/global/{providers,services,utils}/`: shared `ChangeNotifier` state, API clients and business
  services, and utilities. `lib/widgets/common/` holds shared widgets.
- State management uses Provider with `ChangeNotifier`. Use a screen `ChangeNotifier` controller
  when a parent needs imperative control of the screen.
- API services extend `BaseApiService` as singletons. JSON models use `json_serializable` with
  `@JsonSerializable(explicitToJson: true)` where nested objects must be serialized.
- Add an abstraction only when it adds behavior, enforces a boundary, or meaningfully improves
  reuse; call an already available dependency directly.

## Conventions

- Use `AppSymbol` for Material Symbols rather than a direct `Icon`.
- Preserve both the Material and the iOS Liquid Glass navigation paths
  (`CommonProvider.supportsLiquidGlass`).
- Support phone and tablet layouts through `CommonProvider.isTablet`.
- Use DM Sans as the primary font and Itim as the secondary font.
- Take colors from `Theme.of(context).colorScheme`.
- Use `CommonProvider.scaffoldMessengerKey` when a service needs a snackbar without a
  `BuildContext`.
- Use `debugPrint()` for debug logging and guard debug-only behavior with `kDebugMode`.
- Enums under `lib/models/` use uppercase value names, mapping wire strings with `@JsonValue` where
  they differ. Other internal enums follow the surrounding code.

## Errors and UI states

- Catch async errors where the code adds recovery, translation, logging, or user feedback; let
  others propagate. API exceptions live in `lib/global/services/api_exceptions.dart`.
- Report each LTA, NUS, and Transito server call's outcome with `AlertsProvider.reportSuccess` or
  `reportFailure`. The provider decides when to raise or clear an Outage in the Nearby alert inbox,
  so these calls show no snackbars of their own. See transito-server's
  `docs/adr/0001-detect-outages-per-device.md`.
- Present async errors in `FutureBuilder` and similar states with `ErrorText`.

## Canonical examples

- API singleton and LTA failure handling: `lib/global/services/lta_api_service.dart`
- Backend API service: `lib/global/services/transito_api_service.dart`
- Screen controller: `lib/screens/main/nearby_screen.dart`
- Outage and Announcement state: `lib/global/providers/alerts_provider.dart`
- Shared async error UI: `lib/widgets/common/error_text.dart`
