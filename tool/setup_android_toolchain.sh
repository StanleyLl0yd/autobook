#!/usr/bin/env bash
set -euo pipefail

: "${ANDROID_HOME:?ANDROID_HOME is required}"
: "${BUNDLETOOL_JAR:?BUNDLETOOL_JAR is required}"

sdkmanager="$(command -v sdkmanager || true)"
if [[ -z "$sdkmanager" ]]; then
  echo "Android sdkmanager is required." >&2
  exit 127
fi

"$sdkmanager" --sdk_root="$ANDROID_HOME" --install \
  "platforms;android-37.0" \
  "build-tools;36.0.0" \
  "ndk;28.2.13676358"

bundletool_version="1.18.3"
bundletool_sha256="a099cfa1543f55593bc2ed16a70a7c67fe54b1747bb7301f37fdfd6d91028e29"
curl --fail --location --retry 3 \
  "https://github.com/google/bundletool/releases/download/$bundletool_version/bundletool-all-$bundletool_version.jar" \
  --output "$BUNDLETOOL_JAR"
printf '%s  %s\n' "$bundletool_sha256" "$BUNDLETOOL_JAR" | sha256sum --check
