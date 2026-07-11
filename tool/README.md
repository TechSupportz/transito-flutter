# Local user data copier

`copy_prod_user_to_emulator.mjs` copies one production user's app data into the
local Firebase emulators.

It reads `settings/{production-user-id}` and `favourites/{production-user-id}`
from production, creates a new email/password user in the Auth Emulator, and
writes both documents under the new local UID. It never writes to production.

## Prerequisites

1. Start the Transito Firebase emulators. The usual project command is
   `transito-dev`; the Auth and Firestore emulators must be listening on ports
   `9099` and `8088`.
2. Install [Bun](https://bun.sh/) and authenticate `gcloud` with an account that can read the production
   Firestore database:

   ```bash
   gcloud auth application-default login
   ```

   `FIREBASE_ACCESS_TOKEN` can be used instead when a short-lived access token
   is already available.

## Usage

From the Flutter project directory:

```bash
bun tool/copy_prod_user_to_emulator.mjs <production-user-id>
```

The command prints the local email and UID. The email defaults to
`transito-{production-user-id}@local.test`, and the password is always
`Password123`.

An alternative local email can be supplied explicitly:

```bash
bun tool/copy_prod_user_to_emulator.mjs <production-user-id> \
  --email copied-user@local.test
```

If that email already exists in the emulator, use a different `--email` value
or clear the existing local account before copying again.

If only one of the production documents exists, the missing document is
created with the app's defaults. If neither exists, the command stops before
creating a local user.
