# Changelog

[Русская версия](CHANGELOG_RU.md)

All notable changes to AutoBook will be documented in this file.

## [0.1.1] - 2026-09-01

### Added

- Branded Android launcher, adaptive, monochrome, and splash assets.
- In-app About screen with version, author, privacy, license, and source details.
- Database schema, cascade deletion, and non-destructive migration tests.
- Dependabot, structured issue forms, and a private vulnerability-reporting path.
- English and Russian security policies.

### Changed

- Android application identifier is now `com.sl.autobook`.
- Release APK and AAB builds now use R8 minification and resource shrinking.
- CI verifies debug, release APK, and release AAB builds with an ephemeral key.
- Release validation, signing, and publication are isolated into least-privilege jobs.
- Third-party GitHub Actions are pinned to full commit SHAs.
- Android system bars, launcher icons, and splash screens now follow AutoBook branding.

### Security

- Android cloud backup and device-to-device transfer are disabled for local records.
- Release publication is immutable and refuses existing tags or releases.
- APK Signature Schemes v2 and v3, signer count, and APK/AAB certificate fingerprints are verified.
- Gradle distribution downloads are protected by the official SHA-256 checksum.
- Database upgrades fail closed when an explicit migration is missing.

### Upgrade note

- Android treats `com.sl.autobook` as a separate application from the `v0.1.0`
  prototype (`com.silverlightning.autobook`). Installations and local records
  from `v0.1.0` are not upgraded or transferred automatically.

## [0.1.0] - 2026-08-26

### Added

- Initial local-first Flutter prototype architecture.
- Vehicle onboarding and dashboard.
- Mileage history with regression confirmation.
- Service events containing multiple maintenance items.
- Date- and mileage-based next-maintenance calculations.
- Service timeline and annual expense summary.
- Drift/SQLite persistence with no backend dependency.
- Russian and English localization resources.
- Light, dark, and system theme foundations.
- Unit tests for maintenance, mileage, and expense calculations.
