# ADR-0002: Scope Favourite card expansion behaviour

- Status: Accepted
- Date: 2026-07-10

## Context

The main Favourites screen and Nearby Favourites currently reuse the same timing-card widget. Every
card always displays its live Bus Arrivals, and tapping anywhere on the card opens Bus Timing
details. Users need to collapse cards on the main Favourites screen so they can scan Favourite names
without timing rows.

Collapse also affects network activity: each active card currently refreshes Bus Arrivals every 20
seconds even if its timing rows are not visible.

## Decision

- Make cards collapsible only on the main Favourites screen.
- Keep Nearby Favourites cards always expanded.
- Keep the shared timing card non-collapsible by default. Expose collapsibility through an explicit
  widget property supplied by the display: the main Favourites screen opts in, while Nearby and
  other callers retain the existing non-collapsible mode.
- Show only the Favourite Display Name and caret in a collapsed card header.
- Add a synced boolean User Setting that chooses whether Favourites cards initially load expanded or
  collapsed. Existing users and newly provisioned users default to expanded.
- Present the setting under Preferences using the existing two-option `SettingsRadioCard<bool>`
  convention, titled “Favourite cards” with “Expanded by default” and “Collapsed by default”
  options.
- Initialize each card from that setting, then keep manual expansion changes only in the card's local
  widget state while the Favourites screen remains mounted. Do not persist or sync expansion state
  per Favourite; reapply the setting when the screen is recreated.
- When the synced default setting changes, reset all currently mounted collapsible cards to the new
  default immediately so the setting does not appear stale in the kept-alive Favourites tab.
- Make the Favourite name and canonical-caption area open Bus Stop Info. Use the caret as the
  dedicated expand/collapse target. The timing body retains its existing row interactions.
- Fetch and poll Bus Arrivals only while both the Favourites tab and the card are active and
  expanded. Cancel the 20-second refresh timer when a card collapses, and start with a fresh fetch
  when it expands.
- Keep each card's expansion state independent; expanding one card does not collapse another.
- Place a right-aligned caret in the header and animate its rotation over 350 milliseconds. Reveal
  the timing body with a combined size-and-fade transition over 450 milliseconds, using a 300
  millisecond reverse duration.
- Expose expanded/collapsed semantics and a full-size accessible header tap target; the caret remains
  a visual indicator rather than the only interactive target.

## Consequences

- The shared timing-card component must receive an explicit collapse capability rather than making
  every instance collapsible.
- Collapsed cards reduce arrival-request traffic, especially for users with many Favourites.

## Alternatives considered

- Make Nearby Favourites collapsible too. Rejected because it expands the requested feature into a
  separate surface and changes the current Nearby interaction without a demonstrated need.
- Persist expansion state for each Favourite. Rejected because the single synced default setting is
  sufficient and avoids storing transient UI state per Favourite.
- Allow only one expanded card at a time. Rejected because it would be a larger change from the
  current all-expanded list.
- Keep polling while collapsed. Rejected because hidden timing rows do not justify recurring arrival
  requests.
