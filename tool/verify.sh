#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK is required (Flutter 3.47 or newer)." >&2
  exit 127
fi

if [[ ! -d android ]]; then
  flutter create \
    --platforms=android \
    --org app.autobook \
    --project-name autobook \
    .
fi

flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
