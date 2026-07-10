# ADR-0003: Restrict user documents to their owner

- Status: Accepted
- Date: 2026-07-10

## Context

The Firestore rules currently allow any authenticated user to read or write every document. The
Flutter client stores user data under `favourites/{uid}` and `settings/{uid}`. Favourite Aliases may
contain personally meaningful labels such as “Home” or “Work,” increasing the privacy impact of
cross-account access. The reserved `settings/0` document contains public application configuration.

## Decision

- Allow reads and writes to `favourites/{userId}` and its subcollections only when the authenticated
  user's UID equals `userId`.
- Apply the same owner-only rule to `settings/{userId}` and its subcollections.
- Preserve public read access to the reserved `settings/0` application configuration.
- Deny unmatched Firestore document access by default.

## Consequences

- Signed-in users can continue provisioning, reading, updating, and deleting their own Favourite and
  Settings documents.
- Authenticated users can no longer access another user's Favourite Aliases, Favourites, or Settings.
- Any client can continue reading public application configuration from `settings/0`.
- The rules must be verified against the Firebase emulators for allowed owner access and denied
  cross-account access, plus public `settings/0` reads, before release.

## Alternatives considered

- Keep the blanket authenticated-user rule. Rejected because authentication alone does not establish
  ownership of a requested document.
