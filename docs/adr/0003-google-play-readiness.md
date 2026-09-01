# ADR-0003: Google Play Android compatibility baseline

- Status: Accepted
- Date: 2026-09-01

## Context

Google Play requires new apps and updates submitted after August 31, 2026 to
target Android 16 (API 36) or newer. New Play applications are published as
Android App Bundles, must include 64-bit support, and must support 16 KB memory
pages when targeting API 35 or newer.

AutoBook contains native Flutter, Dart JNI, and SQLite libraries. SDK declarations
alone therefore cannot prove compatibility; the final APK and AAB must be
inspected after every release build.

## Decision

- `minSdk` is 26, preserving Android 8.0 and newer devices.
- `targetSdk` is 36, which meets the current Play requirement without enabling
  Android 17 target-only behavior before a dedicated test cycle.
- `compileSdk` is 37 because Android 17 is stable and supported by AGP 9.1.1.
- NDK 28.2.13676358 is pinned because NDK r28 produces 16 KB-aligned native code
  by default.
- The supported ABI set is exactly `armeabi-v7a`, `arm64-v8a`, and `x86_64`.
  ARM64 satisfies Play's 64-bit requirement, ARM32 preserves existing Android
  8 device support, and x86-64 preserves 64-bit ChromeOS support. Legacy x86 is
  excluded because current Flutter releases do not support it.
- The signed AAB is built and published as the primary Google Play artifact.
  A universal signed APK remains an additional GitHub/direct-install artifact.
- CI and release builds verify SDK levels, package ID, ABI and native-library
  parity, every ELF `LOAD` segment, APK 16 KB ZIP alignment, AAB validity, and
  `PAGE_ALIGNMENT_16K` in the bundle configuration.
- The downloaded `bundletool` binary is pinned to version 1.18.3 and its
  published SHA-256 digest.

## Consequences

- Android 7.1 and older devices are no longer supported.
- Google Play can generate optimized per-device APKs from the AAB while GitHub
  users retain a single directly installable APK.
- Any incompatible Flutter engine, Dart JNI, SQLite, or future native dependency
  fails CI before publication.
- Target API 37 remains a future, separately tested migration rather than an
  unnecessary behavior change in this update.
