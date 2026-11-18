Store release notes, one folder per pubspec version name (e.g. `5.3.1/`):

- `android.txt`: Google Play, at most 500 characters, emoji titles.
- `ios.txt`: App Store, ASCII only, at most 4,000 characters.

The `release-notes` skill writes these after you approve the draft. `bundle exec fastlane release`
refuses to run until both exist for the version in `pubspec.yaml`.
