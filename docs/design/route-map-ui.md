# Service Route map UI

UI decisions were confirmed through the design interview. Implementation is authorized on `feature/route-map-ui`.

## Agreed screen design

- Make Bus Service Information itself a map-first screen. The route map remains the underlying surface, with existing service details in a floating bottom panel.
- The panel retains the bus number, operator, terminals, direction selection, ordered stops, and access to stop schedules and Bus Stop Info.
- Existing service-detail entry points open this redesigned screen directly. The separate "View route on map" action is superseded.
- The panel has two positions: a map-view position initially targeting approximately 40% of the screen, and an expanded position that covers most of the map and provides the full service-detail browsing experience. The smaller height is a starting point to iterate, not a fixed constraint.
- Retain handle dragging and tap-to-toggle, along with momentum carrying from panel expansion into list scrolling.
- Terminals and the direction control remain visible in a fixed panel header in both positions. Bus number and operator also remain visible. The stop list scrolls beneath the header.
- Start with the current terminal-card UI rather than replacing it with compact terminal rows.
- Stop-card taps depend on the panel position: in the smaller map-view position, focus the stop on the map; when expanded, open Bus Stop Info. This applies to both terminal cards and route-list cards.
- Focusing a stop centres and zooms the map to street level, placing the stop in the visible map area above the panel.
- Map-marker taps select and highlight the stop, then scroll its matching card into view in the panel. They do not open Bus Stop Info directly.
- Switching direction fits the newly selected route and clears the selected stop. Retain the originating-stop highlight if that stop belongs to the newly selected direction.
- Back leaves the service screen, including when the panel is expanded. Use the panel handle to collapse it. Returning from Bus Stop Info restores the camera, panel height, and list position.

## Agreed requirements carried forward

- Display one selected Service Route at a time using the current direction control in the panel header.
- Initially fit the whole route and highlight the originating Bus Stop when one is available.
- Show only the selected route's Bus Stop markers and retain the user's location dot.
- Use one map marker per physical Bus Stop, even when the Service Route visits it more than once. Preserve those separate occurrences in the ordered stop list.
- Retain the current first-match list behaviour when selecting a deduplicated marker: reveal the first matching stop occurrence. A card tap identifies that specific list occurrence.
- The selected stop's name is shown through its card in the floating bottom panel.
- When a Route Shape is unavailable, retain the route's Bus Stop markers and omit the line. Show no explicit missing-shape message and do not connect stops with straight lines.
- Show stop placeholders during route loading. Use the standard error-card presentation for failed service or route requests, with a Retry action. A missing Route Shape alone is not a request failure.
- Reuse the normal map's compass icon to restore the whole route north-up, framed in the visible map area above the panel. Make it available whenever the camera has moved away from that overview.
- Keep panel height flexible for short screens and larger text. Preserve readable names, accessible action labels and touch targets, and both Material and Liquid Glass presentation paths.

## Deferred

- A dedicated tablet side-panel layout. Focus the initial revision on the phone UI; iterate tablet presentation later.

## Visual iteration

- Panel height and spacing are intentionally left for visual iteration using the current cards. The smaller panel grows to accommodate its fixed header and at least one stop card.

## Full-screen revamp

Supersedes the floating inset panel, the app bar, and the whole-route overview above.

- The map fills the screen, including under the status bar, as on Search. There is no app bar. A floating back button sits top-left and the compass top-right in the same row.
- The panel is a full-width Material bottom sheet (`DraggableScrollableSheet` with native snapping, standard surface, elevation, 28dp top corners and 32×4 drag handle). It snaps between a small size and an expanded size that stops below the floating controls, so Back stays reachable. Native snapping drops fling momentum at the expanded stop; a second swipe scrolls the list.
- The header is pinned inside the sheet's scroll view and dragging it always moves the sheet, even after the list has scrolled to a stop. If the header is taller than half the expanded sheet (for example with very large text), it scrolls away with the list instead and only the handle drags the sheet.
- The header shows a "Bus N" heading with the operator chip, then one grouped card holding both terminals laid out like `BusStopCard` content (name, code chip, road). Each terminal is led by its green origin or red destination icon, matching the timeline, and the direction switch sits on the right. Loop services show one terminal with the loop icon. Full `BusStopCard`s with a separate icon column, and a boxed From/To card with small labels, were tried first.
- Stops are a timeline: a route rail with green start and red end terminal nodes, stop name, code chip, road, and a First and last bus action. The origin stop has a filled node and a "Your stop" tag; the selected stop has a tonal row highlight. Rows share one extent, so marker selection scrolls exactly to a row at any text size.
- The map does not open on a whole-route overview, which is cluttered on OneMap tiles. It opens at street level on the originating stop when it is on the selected route, otherwise on that route's starting terminal. The compass and direction switch return to this view north-up.
- The route line uses the operator's colour (NUS shuttles use their service colour), with no outline. It is lightened on the Night tiles, and pale colours such as GAS yellow are darkened on the Default tiles so they don't blend into yellow main roads. Stops sit on it like a transit map: white markers ringed in the route colour, a route-coloured rounded square for the origin, green and red terminals, and an enlarged marker for the selected stop. Terminals keep their colours when selected; the origin marker takes precedence when the origin is a terminal. Resetting the camera or switching direction collapses an expanded sheet so the target isn't hidden.
- When the originating stop is on the selected route and the next arriving bus has live monitored coordinates on that direction, an inverted high-contrast teardrop pin (dark surface on Default tiles, light surface on Night tiles) ringed in the route colour with a pulsing halo marks that bus on the map and refreshes every 20 seconds. Departed, unmonitored, stale, or off-route positions are hidden, and nearby positions snap onto the route line.
- Route Shapes may end short of interchange stops that sit off the road. The app leaves that gap rather than drawing a connecting segment.

## Stop actions

Supersedes the position-dependent card taps above ("focus when small, open Bus Stop Info when expanded"), which hid the way into a stop's timings.

- Tapping a stop row or terminal card always selects the stop and focuses it on the map. An expanded sheet collapses first so the stop is visible. Map markers select the stop as before.
- The selected row expands to show three actions: Timings (opens Bus Timing directly), Schedule (first and last bus), and Info (Bus Stop Info). Rows no longer carry their own schedule button.
- The small sheet starts at 60% of the screen and grows if the header and one stop need more room.
