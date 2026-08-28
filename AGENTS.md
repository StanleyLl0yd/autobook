# Repository Instructions

## Product boundaries

- Keep AutoBook local-first and functional without an account or permanent
  network connection.
- Do not add analytics, advertising, tracking, GPS, OBD, or a backend without
  an explicit product decision.
- Treat service history as user-owned data. Schema changes require an explicit,
  tested, non-destructive migration.

## Engineering standards

- Use the existing presentation, domain, data, and database boundaries.
- Keep comments rare, current, necessary, and in English only.
- Never commit credentials, signing material, local databases, generated build
  output, or personal vehicle data.
- Keep release signing in GitHub Actions secrets and verify the expected
  signing-certificate fingerprint before publication.
- Pin third-party GitHub Actions to full commit SHAs.
- Prefer small commits with one coherent purpose.

## Verification

Run `./tool/verify.sh` before completing a change. Changes affecting Android
packaging or signing must also build release APK and AAB outputs in CI.
