# ADR-0005: Follow service routes for the distance of an arriving bus

- Status: Accepted
- Date: 2026-10-08

## Context

Bus timing rows show how far the next bus is from the Bus Stop. The distance was measured as a
straight line between the bus and the stop, which badly understates it when a service winds, loops,
or travels away from the stop before returning.

LTA Bus Routes supply a cumulative Route Distance for every stop, rounded to 0.1 km. NUS pickup
points have no distance, but the NUS `checkpoint-bus-stop` path does. LTA arrivals are requested
directly from DataMall and refreshed every 20 seconds, so a request to the US-hosted Transito
server, or to a routing API, on that path would add latency and another point of failure.

## Decision

- transito-server builds a compact Route Distance Index at the end of each `generateJSON` run and
  uploads it to `route-distances/v1.json.gz` in the project's Singapore-region Firebase Storage
  bucket. It skips the upload when the content is unchanged. NUS distances come from the
  `checkpoint-bus-stop` path.
- The app starts `RouteDistanceService` at launch and checks again whenever it resumes. It loads its
  cached copy, compares the remote object's `md5Hash` at most once a day, retries failures after
  five minutes, and downloads and caches a changed index in the background. A download is decoded
  before it replaces the cache.
- No copy of the index is bundled with the app. Until one is available, rows use the straight line.
- For each arrival, `busDistanceAway` selects routes containing the arrival's `OriginCode`, the
  `VisitNumber`th occurrence of the Bus Stop after it, and the closest route segment before that
  occurrence. A blank LTA `VisitNumber`, and every NUS one because transito-server always reports
  the first visit, is treated as unknown, so every occurrence is considered. The remaining
  distance is the stop's Route Distance minus the bus's interpolated position on that segment.
- Use the straight line when the bus position is missing, the service or origin is not in the
  index, the stop is the trip's origin, the bus is more than 250 m from every candidate segment,
  the remaining distances of the closest segments, those within 40 m of the best match, span more
  than 300 m, or the result is negative.
- Never show less than the straight-line distance, which bounds the rounding error in LTA's
  distances.
- The schema version is part of the object path and cache file, so a future format can be published
  alongside the old one without breaking installed apps.
- Index download failures are only logged. Firebase Storage is not an Outage source.

## Consequences

- Opening or refreshing timings makes no additional request; the direct LTA arrival request remains
  the only live request for LTA services.
- The index follows the server's weekly data refresh, so the app picks up route changes within about
  a day of the server.
- A fresh install, or a device that has never reached Firebase Storage, shows straight-line
  distances until its first successful download.
- The app depends on `firebase_storage`, and local development runs the Storage emulator on port
  9199. `storage.rules` must be deployed before release.
- On a route that repeats a stop, a bus before the first visit falls back to the straight line when
  the visit is unknown, because both visits are plausible.

## Alternatives considered

- Bundle a snapshot in the app. Rejected because it ties route data to app releases and diverges
  from the server between them.
- Serve the index from a Transito server endpoint. Rejected in favour of Firebase Storage, which is
  in Singapore, needs no new endpoint, and keeps downloads off the server.
- Fetch each service's route from the existing service endpoint on first use. Rejected because the
  first view of each service would show a straight line and then change.
- Calculate the distance on the server per request. Rejected because it puts a network request on
  the timing path.
- Sum straight lines between NUS stops. Rejected because it understates NUS routes by 20–45%
  compared with the checkpoint path.
