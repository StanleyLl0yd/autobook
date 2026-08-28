# AutoBook

[![Flutter CI](https://github.com/StanleyLl0yd/autobook/actions/workflows/ci.yml/badge.svg)](https://github.com/StanleyLl0yd/autobook/actions/workflows/ci.yml)
[![Latest release](https://img.shields.io/github/v/release/StanleyLl0yd/autobook?display_name=tag)](https://github.com/StanleyLl0yd/autobook/releases/latest)
[![Release downloads](https://img.shields.io/github/downloads/StanleyLl0yd/autobook/total)](https://github.com/StanleyLl0yd/autobook/releases)
[![License: PolyForm Noncommercial](https://img.shields.io/badge/license-PolyForm%20Noncommercial-blue)](LICENSE)

[Русская версия](README_RU.md)

AutoBook is a private, local-first service history for a personal vehicle. It
keeps mileage, maintenance, costs, and upcoming work together without an
account, backend, analytics, advertising, or a permanent network connection.

> Your vehicle history and everything that comes next.

## Current scope

The `0.1.1` source release includes:

- vehicle onboarding and dashboard;
- mileage updates with regression confirmation and immutable history;
- service events containing multiple maintenance items;
- kilometre- and date-based maintenance schedules;
- chronological history and annual expense summaries;
- local Drift/SQLite persistence;
- Russian and English interfaces;
- light, dark, and system themes;
- a branded Android launcher and splash experience;
- an in-app About screen with version, privacy, license, and source details.

## Install

Download the signed APK from the
[latest GitHub Release](https://github.com/StanleyLl0yd/autobook/releases/latest).
Releases from `v0.1.1` also include an Android App Bundle and a shared SHA-256
checksum file.

Android may ask you to allow installation from your browser or file manager.
Only install assets published in this repository and compare their checksums
when transferring them through another service.

## Data and privacy

AutoBook stores its data in the on-device `autobook.sqlite` database. The
release manifest does not request Internet access, and Android cloud backup and
device-to-device transfer are disabled to prevent vehicle history from leaving
the device implicitly.

There is no account, telemetry, analytics SDK, advertising SDK, GPS, OBD, or
backend. Uninstalling the application deletes its local data. Export and
user-controlled backup are planned but are not available yet.

## Development

Requirements:

- Flutter 3.47.1;
- Dart 3.12 or newer;
- JDK 17;
- an Android toolchain configured for Flutter.

Run the complete local verification:

```bash
./tool/verify.sh
```

The script resolves dependencies, checks formatting, runs static analysis and
tests, and builds a debug APK. GitHub CI additionally creates R8-minified,
resource-shrunk release APK and AAB verification artifacts with an ephemeral
CI key.

## Architecture

```text
presentation (screens and Riverpod providers)
             ↓
domain (models and pure calculations)
             ↓
data (repository and Drift/SQLite)
```

The application deliberately keeps a small number of layers. Drift custom
statements keep the schema and migrations explicit, while repositories expose
typed domain objects and streams. Service costs remain the source of truth for
expense summaries, so an event cannot be counted twice.

- [ADR-0001: Prototype architecture](docs/adr/0001-prototype-v0.1.md)
- [ADR-0002: v0.1.1 hardening](docs/adr/0002-v0.1.1-hardening.md)

## Release integrity

Signed releases are built only by the
[Android Release workflow](.github/workflows/release.yml). Validation,
building/signing, and publication run as separate jobs with least-privilege
permissions. Third-party Actions are pinned to full commit SHAs.

The workflow:

1. requires a `vMAJOR.MINOR.PATCH` tag matching `pubspec.yaml`;
2. runs formatting, analysis, and tests;
3. builds an R8-minified APK and AAB with the protected release key;
4. verifies APK Signature Schemes v2 and v3, one APK signer, and the expected
   certificate fingerprint for both APK and AAB;
5. generates SHA-256 checksums and publishes a new immutable GitHub Release.

Signing material is supplied through the protected `release` environment and
GitHub Actions secrets, then removed from the runner. Existing tags and
releases are never overwritten.

## Roadmap

- **v0.2:** edit and safely delete saved records;
- **later v0.2 increments:** user-controlled export and backup, then reminders;
- **future:** multiple vehicles, attachments, richer statistics, and optional
  encrypted synchronization.

The local-first privacy boundary remains the default for every increment.

## Security

Report vulnerabilities privately as described in [SECURITY.md](SECURITY.md).
Do not publish signing material, passwords, or personal vehicle records in an
Issue.

## License

Copyright 2026 Stanley Lloyd. AutoBook is licensed under the
[PolyForm Noncommercial License 1.0.0](LICENSE). Commercial use requires a
separate license from the copyright holder.
