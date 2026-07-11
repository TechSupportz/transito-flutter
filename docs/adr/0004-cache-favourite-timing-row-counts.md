# ADR-0004: Cache Favourite timing row counts for stable loading layouts

- Status: Accepted
- Date: 2026-07-11

## Context

The main Favourites screen uses a lazily built list. Timing cards that move sufficiently far
off-screen can be disposed and reconstructed, which starts a fresh Bus Arrival request. The card
shows skeleton rows while that request is pending.

The skeleton currently uses the number of selected services, but the arrival response can display
fewer services. Its row spacing and bottom padding also differ from the loaded timing list. When a
reconstructed card changes from its estimated skeleton height to its returned timing height, every
card below it moves. This is especially visible while slowly scrolling upward.

## Decision

- Keep an in-memory timing-row-count cache owned by the main Favourites screen. The cache lasts only
  for that screen's mounted session and is not persisted or synced.
- Key cache entries by Bus Stop code. Store only the selected-service count and the last positive
  displayed-row count; do not retain service identities or arrival data.
- Reuse a cached displayed-row count only while the selected-service count is unchanged. Fall back
  to the current selected-service count after additions or removals invalidate the entry.
- Have the shared Favourite timing card accept an optional placeholder-row count and report
  successful positive displayed-row counts. Keep both properties optional so Nearby Favourites and
  other callers preserve their current behaviour and can opt into caching later.
- Ignore zero-row responses when updating the cache. Show the existing empty-timings message within
  the space reserved by the last cached count, or by the selected-service count when no cached count
  exists.
- Preserve the same reserved timing-area height for initial-load and settings errors.
- Show timing-row skeletons while either User Settings or Bus Arrivals are loading instead of using
  a smaller settings spinner.
- Give skeleton and loaded lists identical row extent, separator spacing, and bottom padding so an
  equal row count produces an equal card height.
- Use `ListView.builder` with `itemExtentBuilder` so the outer varied-extent sliver knows every
  Favourite card's complete height even after discarding its widget. Calculate each extent from its
  fixed header height, cached timing-row count, expansion progress, and following separator.
- Keep card expansion state and its extent animation in the main Favourites list. Drive the supplied
  extent with the same 450 millisecond expand and 300 millisecond collapse curves as the timing-body
  transition so collapsible cards retain their animated behaviour.
- Use Flutter's default list cache extent rather than retaining multiple extra viewports of timing
  cards.
- Build the small timing-row and skeleton groups as `Column`s rather than nested shrink-wrapped
  `ListView`s.
- Reuse the main Favourites screen's User Settings snapshot in its cards. Preserve the card's own
  settings stream as the default for Nearby Favourites and other independent callers.
- Do not rebuild the Favourites list to update Floating Action Button visibility. Skip scroll
  visibility handling entirely under Liquid Glass, where the Material FAB is absent, and isolate
  the Material FAB with a `ValueNotifier` elsewhere.
- Allow a later positive response with a genuinely different displayed-row count to update the
  cache and resize the card once.
- Keep the existing 20-second refresh presentation, including replacing rows with skeletons while a
  refresh is pending.

## Consequences

- Reconstructed off-screen Favourite cards reserve the height of their last successful timing
  layout, preventing the common scroll-position shift when timings reappear.
- The first load still estimates row count from selected services because no response-derived count
  exists yet.
- Empty and error states can contain additional vertical space in order to preserve surrounding
  layout.
- Nearby Favourites remains unchanged unless its parent later supplies a session cache.
- The sliver can calculate positions for discarded cards without retaining their widgets, arrival
  requests, or polling timers.
- Alias-bearing headers reserve their expanded caption height even while collapsed so their complete
  extent remains deterministic.

## Alternatives considered

- Persist row counts across app launches. Rejected because row availability is transient and stale
  persisted layout data is not worth the storage and invalidation complexity.
- Cache exact selected-service identities. Rejected because layout depends on the count, and storing
  identities adds no value for the requested stabilization.
- Keep obsolete empty skeleton slots after a positive row-count change. Rejected because permanent
  unexplained gaps are worse than a single resize reflecting a genuine response change.
- Replace rows only after a background refresh succeeds. Deferred because the current refresh
  presentation is acceptable; retaining stale rows can be revisited if skeleton flashing becomes
  distracting.
- Keep every Favourite card alive after it has been built. Rejected because expanded cards would
  retain timers and poll indefinitely even when far from the viewport.
- Increase the list cache extent by multiple viewports. Rejected because it only postpones extent
  correction and makes long lists and tab switching more expensive.
