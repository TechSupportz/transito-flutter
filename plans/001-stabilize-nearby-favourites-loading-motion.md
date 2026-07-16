# 001 — Stabilize Nearby favourites loading motion

- **Status**: DONE
- **Commit**: ac49bfc
- **Severity**: HIGH
- **Category**: Performance, physicality, easing, and accessibility
- **Estimated scope**: 2 Dart files, roughly 45–65 changed lines

## Implemented refinement

The initial opacity-only switcher described below was implemented and then refined after the feel
check exposed a double-fade flash and removed too much of the useful layout motion. The final result:

- Keeps the `flutter_skeleton_ui` shimmer as a loading-only subtree and fades results in with a
  local 150ms `TweenAnimationBuilder`.
- Avoids toggling the package's internal `AnimatedSwitcher`, which can retain two unkeyed shimmer
  children and throw a duplicate-key assertion when refresh is tapped rapidly.
- Uses a full-width, top-aligned 250ms `AnimatedSize` only for the section's vertical layout shift.
- Uses `Duration.zero` when platform animations are disabled.
- Reserves the favourite card's complete timing-row skeleton height outside the shimmer widget, as
  required by ADR-0004, so the shimmer's first empty frame cannot collapse the card.
- Gives Nearby its own ADR-0004 session cache so reconstructed cards reserve the last positive
  displayed timing-row count while the selected-service count remains unchanged.

This refinement touches `lib/screens/main/nearby_screen.dart` and
`lib/widgets/favourites/favourite_timing_rows_skeleton.dart`. The original target below is retained
as the implementation history that led to the final feel check.

## Problem

The Nearby favourites loading/result subtree is wrapped in `AnimatedSize`. The animation responds
to every size change below it, including the skeleton package's temporary zero-size first layout and
later timing-card height corrections. Because `AnimatedSize` defaults to centered alignment, a
loading skeleton can appear to expand in both width and height. The animation also uses a generic
300 millisecond curve and does not honor the platform's reduced-motion setting.

Keep the existing product decision that a refresh replaces the cards with a skeleton. This plan
changes only how the loading and result states transition.

```dart
// lib/screens/main/nearby_screen.dart:317 — current
AnimatedSize(
  duration: const Duration(milliseconds: 300),
  curve: Curves.ease,
  child: FutureBuilder(
    future: nearbyFavourites,
    builder: (BuildContext context, AsyncSnapshot<List<NearbyFavourites>> snapshot) {
      Widget favouritesListWidget = const SizedBox();

      // State selection omitted here; retain its current data, empty, and error behavior.

      return Skeleton(
        isLoading: snapshot.connectionState == ConnectionState.waiting,
        skeleton: SkeletonLine(
          style: SkeletonLineStyle(height: 128, borderRadius: BorderRadius.circular(12)),
        ),
        child: favouritesListWidget,
      );
    },
  ),
),
```

The `flutter_skeleton_ui` package can temporarily return an unconstrained empty `SizedBox` while
its shimmer ancestor obtains a render size. That zero-size intermediate child is what gives the
outer `AnimatedSize` a `0×0` starting point.

## Target

- Remove `AnimatedSize` from around the complete favourites subtree.
- Continue showing the existing 128 logical-pixel skeleton whenever the future is waiting,
  including user-initiated refreshes and location refreshes.
- Reserve the skeleton's full width and 128 logical-pixel height outside the third-party `Skeleton`
  widget. Its internal first-frame empty box must not collapse the section.
- Crossfade loading, data, empty, and error states using `AnimatedSwitcher`.
- Animate only opacity; do not animate width, height, scale, position, padding, or margins.
- Anchor outgoing and incoming children to `Alignment.topCenter`, so a tall loaded list does not
  reposition the outgoing 128px skeleton toward its vertical center.
- Use exactly 200 milliseconds for the crossfade, `Easing.emphasizedDecelerate` for the entering
  child, and `Easing.emphasizedAccelerate` for the outgoing child.
- When `MediaQuery.disableAnimationsOf(context)` is true, use `Duration.zero`. The shimmer may
  continue as the loading/progress indication; the state swap itself must be immediate.
- Give each top-level switcher state a stable, distinct key so every loading/result change triggers
  one intentional crossfade.

The resulting transition wrapper should have this exact shape:

```dart
final Duration loadingTransitionDuration = MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 200);

return SizedBox(
  width: double.infinity,
  child: AnimatedSwitcher(
    duration: loadingTransitionDuration,
    switchInCurve: Easing.emphasizedDecelerate,
    switchOutCurve: Easing.emphasizedAccelerate,
    layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
      return Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      );
    },
    transitionBuilder: (Widget child, Animation<double> animation) {
      return FadeTransition(opacity: animation, child: child);
    },
    child: favouritesListWidget,
  ),
);
```

The waiting state must reserve its size outside `Skeleton`:

```dart
const SizedBox(
  key: ValueKey<String>('nearby-favourites-loading'),
  width: double.infinity,
  height: 128,
  child: Skeleton(
    isLoading: true,
    skeleton: SkeletonLine(
      style: SkeletonLineStyle(
        height: 128,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    child: SizedBox.expand(),
  ),
)
```

Use these state keys:

- Waiting skeleton: `ValueKey<String>('nearby-favourites-loading')`
- Non-empty list: `ValueKey<String>('nearby-favourites-results')`
- Empty result: `ValueKey<String>('nearby-favourites-empty')`
- Error result: `ValueKey<String>('nearby-favourites-error')`

Wrap the non-empty `ListView.separated` and `ErrorText` in `KeyedSubtree` where necessary so the
keys identify the top-level switcher children without disturbing the existing bus-stop-code keys on
individual `FavouritesTimingCard` instances.

## Repo conventions to follow

- Material 3 easing curves are used directly from Flutter's `Easing` class; do not introduce a new
  motion-token file for this one screen.
- `lib/widgets/favourites/favourites_timing_card.dart:396` uses
  `Easing.emphasizedDecelerate` for entering content and `Easing.emphasizedAccelerate` for outgoing
  content.
- `lib/widgets/onboarding/quick_start_tour_overlay.dart:420` uses an opacity-only
  `AnimatedSwitcher` via `FadeTransition`.
- `lib/widgets/onboarding/quick_start_tour_overlay.dart:421` selects `Duration.zero` through
  `MediaQuery.disableAnimationsOf(context)`.
- Keep theme colors sourced through `Theme.of(context).colorScheme`.

## Steps

1. Edit `lib/screens/main/nearby_screen.dart` only.
2. In `nearbyFavouritesList`, compute `loadingTransitionDuration` from
   `MediaQuery.disableAnimationsOf(context)`, using zero or exactly 200 milliseconds.
3. Remove the outer `AnimatedSize`, including its 300 millisecond duration and `Curves.ease`.
4. In the `FutureBuilder` builder, select one keyed top-level widget for each state. Check the
   waiting state first so refreshes continue to show the skeleton even if the snapshot temporarily
   retains old data.
5. Build the waiting state as a full-width, 128px `SizedBox` containing an always-loading
   `Skeleton`. Do not let the third-party widget determine the outer placeholder extent.
6. Preserve the current non-empty list, empty message, and error message contents. Add only their
   top-level switcher keys; do not change card data, spacing, or error copy.
7. Return the full-width `AnimatedSwitcher` shown in the Target section. Use its custom
   top-centered `Stack` layout and opacity-only transition.
8. Run `dart format lib/screens/main/nearby_screen.dart`.
9. Run `flutter analyze` and resolve only diagnostics caused by this edit.

## Boundaries

- Do NOT change `getAllNearby`, `streamUserLocation`, the 50m location filter, or future lifecycle.
- Do NOT preserve stale cards during refresh; the selected behavior is to show the skeleton.
- Do NOT edit `FavouritesTimingCard` or add Nearby timing-row caching.
- Do NOT change the Nearby bus-stop grid loading UI.
- Do NOT change skeleton colors, shimmer speed, card dimensions, copy, or spacing.
- Do NOT add dependencies or modify `pubspec.yaml`.
- Do NOT run the development stack or any Shorebird command. The user owns startup through the
  `transito-dev` fish alias.
- If these code locations have materially drifted from commit `ac49bfc`, stop and report the drift
  instead of improvising.

## Verification

- **Mechanical**:
  1. Run `dart format lib/screens/main/nearby_screen.dart`; it must complete without error.
  2. Run `flutter analyze`; it must report no new diagnostics from this change.
- **Environment check before requesting an app launch**:
  1. Run `lsof -nP -iTCP:8080 -sTCP:LISTEN`.
  2. Run `lsof -nP -iTCP:4000 -sTCP:LISTEN`.
  3. If either port is not listening, do not start the stack. Ask the user to run `transito-dev`.
- **Feel check** on phone and tablet widths:
  - Cold-load Nearby. The skeleton occupies full content width and 128px height immediately; it
    never grows outward from the center.
  - Pull to refresh with one and with several nearby favourites. Loaded cards fade to the skeleton,
    and the skeleton fades to the new cards. Width never animates.
  - Watch the top edge in slow motion. The skeleton and loaded list remain pinned beneath the
    `Nearby Favourites` heading; neither child shifts toward the center of the taller state.
  - Wait for individual bus timings to resolve. Their height corrections are not animated by a
    section-level size tween.
  - Enable the platform's reduced-motion/Remove Animations setting and repeat cold load and refresh.
    State swaps are immediate while the loading skeleton remains visible during the request.
  - In Flutter DevTools' frame chart, refresh several nearby favourites. Confirm there is no
    continuous 300ms relayout attributable to `RenderAnimatedSize`.
- **Done when**: refresh still visibly enters a skeleton state, every top-level state change is
  opacity-only at normal motion settings, reduced-motion swaps are immediate, and no horizontal or
  vertical expansion animation remains around the favourites section.
