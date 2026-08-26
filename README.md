# AutoBook

[Русская версия](README_RU.md)

AutoBook is a local-first digital service history for a personal vehicle. It keeps mileage, maintenance events, costs, and upcoming work together without requiring an account or backend.

> All your vehicle history — and everything that needs to happen next.

## Prototype v0.1

The current vertical slice includes:

- vehicle creation;
- dashboard with current mileage, upcoming maintenance, and recent work;
- mileage updates with regression confirmation;
- service events with multiple maintenance items;
- kilometre- and date-based maintenance intervals;
- chronological service history;
- annual expense summary derived from service events;
- local SQLite persistence through Drift;
- Russian and English UI strings;
- light, dark, and system theme support.

No backend, authorization, telemetry, AI, OCR, GPS, OBD, advertising, or marketplace integration is included.

## Requirements

- Flutter 3.47 or newer;
- Dart 3.12 or newer;
- Android toolchain configured for Flutter.

## Run locally

```bash
./tool/verify.sh
flutter run
```

The verification script resolves dependencies, checks formatting and analysis,
runs tests, and builds a debug APK.

## Signed Android releases

Signed APKs are built only by the
[Android Release workflow](.github/workflows/release.yml). The release keystore
and passwords are stored as encrypted GitHub Actions secrets and are never
committed to the repository.

Required repository secrets:

- `ANDROID_KEYSTORE_BASE64`;
- `ANDROID_KEYSTORE_PASSWORD`;
- `ANDROID_KEY_ALIAS`;
- `ANDROID_KEY_PASSWORD`.

The workflow validates formatting and static analysis, runs all tests, builds a
release APK, verifies its signing-certificate fingerprint, publishes the APK
and SHA-256 checksum as workflow artifacts, and creates the corresponding
GitHub Release.

## Architecture

```text
presentation (screens + Riverpod providers)
             ↓
domain (models + pure calculations)
             ↓
data (repository + Drift/SQLite)
```

The application deliberately uses a small number of layers. Drift custom statements keep schema and migrations explicit while repositories expose typed domain objects and streams. Service costs are the source of truth for the expense summary, so a service event cannot be counted twice.

See [ADR-0001](docs/adr/0001-prototype-v0.1.md) for the data model, navigation flow, and trade-offs.

## Data and privacy

Prototype data stays on the device in `autobook.sqlite`. There is no network dependency. Vehicle IDs and event IDs are UUIDs to keep a future local-first sync path open.

## Roadmap

- **v0.1:** one vehicle, mileage, service history, maintenance schedule, expenses;
- **v0.2:** multiple vehicles, reminders, parts, warranties, documents;
- **v0.3:** photos, PDF/CSV/JSON export, simple statistics;
- **v0.5+:** optional encrypted backup and synchronization.

## License

A project license has not been selected yet.
