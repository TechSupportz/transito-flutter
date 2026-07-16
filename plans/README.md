# Animation plans

| Number | Plan | Severity | Status |
| --- | --- | --- | --- |
| 001 | [Stabilize Nearby favourites loading motion](001-stabilize-nearby-favourites-loading-motion.md) | HIGH | DONE |

## Recommended execution order

1. Execute plan 001. It combines audit findings 1 and 4 because both change the same transition in
   `lib/screens/main/nearby_screen.dart`.

## Dependencies

- Plan 001 has no dependencies and must not alter the chosen refresh behavior: a refresh continues
  to replace Nearby favourites with a skeleton while data is loading.
