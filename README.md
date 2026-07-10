# Climber Speed Timer

Flutter **Web** speed-climbing timer for gym sessions. Track up to 10 athletes, time runs to centiseconds, export CSV, and keep the current session in browser storage.

## Live demo

https://pvtvv.github.io/climber-app/

## Local run

Requires a Linux/macOS Flutter SDK (stable) with web enabled.

```bash
flutter pub get
flutter run -d chrome
```

Or serve a release build:

```bash
flutter build web --base-href /climber-app/
# then open build/web with any static server
```

## Features

- Add athletes (max 10) with distinct colors
- Expand an athlete to view runs; sort by time
- Time a run with Start / Stop / Save / Cancel
- Export all athletes’ runs as CSV
- New Session: Save (export then clear) or Cancel (clear only)
- Session persists in `localStorage` across reloads

## Tests

```bash
flutter test
```

## Deploy

Pushes to `main` build and deploy via GitHub Actions (`.github/workflows/deploy.yml`) to GitHub Pages with `--base-href /climber-app/`.
