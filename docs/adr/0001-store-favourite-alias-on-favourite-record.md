# ADR-0001: Store Favourite aliases on Favourite records

- Status: Accepted
- Date: 2026-07-10

## Context

A Favourite currently stores both its canonical Bus Stop identity and the data needed to display
live Bus Arrivals. Users need to give a Favourite a personal label without changing official Bus
Stop data.

The Bus Stop name is refreshed from the transport catalogue when a Favourite is edited. Reusing
that field for a personal label would allow a catalogue refresh to erase the label and would leak
user-authored text into official search, map, and detail surfaces.

## Decision

- Store a Favourite Alias as an optional field on the Favourite record.
- Allow users to set the optional alias when adding a Favourite and change it later when editing the
  Favourite.
- Place the alias field directly on the existing Add and Edit Favourite screens, above the
  bus-service checklist, and save it with the same form action rather than opening a separate rename
  dialog.
- Show alias validation errors inline and block Add/Save while the alias exceeds 40 characters or
  exactly duplicates another Favourite Alias. Empty input remains valid and clears the alias.
- Trim alias input before saving. Store an empty or whitespace-only value as `null`, which restores
  the canonical Bus Stop name as the Favourite Display Name.
- Limit aliases to 40 user-perceived characters.
- Accept punctuation and emoji, but reject line breaks and control characters so aliases remain
  single-line labels.
- Require every non-null Favourite Alias to be unique within that user's Favourites using a simple,
  case-sensitive comparison against other non-empty alias fields after trimming. For example,
  `Home` and `home` may coexist. Do not compare the input with canonical Bus Stop names.
- Preserve the canonical Bus Stop name separately and continue identifying a Favourite by its
  canonical Bus Stop code.
- Derive the Favourite Display Name from the alias when present, falling back to the canonical Bus
  Stop name.
- Use the Favourite Display Name on Favourite-specific surfaces: Favourites cards, collapsed
  Favourites headers, Nearby Favourites cards, and Manage Favourites.
- When an alias exists, show it as the expanded card's primary heading and show the canonical Bus
  Stop name beneath it using caption-style supporting text. Hide the canonical caption when the card
  is collapsed. Do not repeat the canonical name when no alias is present.
- Continue using the canonical Bus Stop name as the primary name in search, map, Bus Stop Info, and
  Bus Timing detail surfaces. When Bus Stop Info finds that the stop is a Favourite with a non-empty
  alias, show the alias as caption-style supporting text beneath the canonical heading.
- Treat a missing alias field as no alias so existing Firestore records remain compatible.

## Consequences

- Favourite edit and rewrite paths must preserve the alias when refreshing canonical Bus Stop data
  or changing selected services.
- Shared Favourite cards must receive both canonical and display names so navigation can retain
  official Bus Stop terminology.
- Bus Stop Info should reuse its existing Firestore Favourite lookup to obtain both membership and
  alias, avoiding a second query solely for the caption.
- Existing favourites do not require a data migration.
- Add and edit flows must validate alias uniqueness against the user's other Favourites.
- Alias uniqueness is a simple in-app, best-effort validation against the loaded Favourites and is
  not enforced with a Firestore transaction. Concurrent saves from separate devices may therefore
  rarely create duplicates.

## Alternatives considered

- Overwrite the canonical Bus Stop name with the alias. Rejected because it conflates user-owned
  and provider-owned data and can be overwritten by catalogue refreshes.
- Limit aliases to the main Favourites screen. Rejected because the label would not consistently
  follow the Favourite into Nearby Favourites and Manage Favourites.
- Use an alias as the primary name in search, map, and detail surfaces. Rejected because those
  surfaces describe the canonical Bus Stop. Bus Stop Info may expose the alias as supporting context
  without replacing its canonical heading.
- Allow multiple Favourites to share an alias. Rejected because indistinguishable personal labels
  would confuse users even though canonical Bus Stop codes remain unique.
- Enforce alias uniqueness in a Firestore transaction. Rejected as disproportionate complexity for
  this display-label rule; a simple client-side check is sufficient.
