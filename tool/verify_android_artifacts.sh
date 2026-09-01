#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <release.apk> <release.aab>" >&2
  exit 64
fi

apk="$1"
aab="$2"
: "${ANDROID_HOME:?ANDROID_HOME is required}"
: "${BUNDLETOOL_JAR:?BUNDLETOOL_JAR is required}"

for artifact in "$apk" "$aab" "$BUNDLETOOL_JAR"; do
  if [[ ! -s "$artifact" ]]; then
    echo "Required artifact is missing or empty: $artifact" >&2
    exit 1
  fi
done

build_tools_dir="$(
  find "$ANDROID_HOME/build-tools" -type f -name aapt -print |
    sed 's#/aapt$##' |
    sort -V |
    tail -n 1
)"
aapt="$build_tools_dir/aapt"
zipalign="$build_tools_dir/zipalign"
readelf="$(
  find "$ANDROID_HOME/ndk/28.2.13676358/toolchains/llvm/prebuilt" \
    -type f -name llvm-readelf -print |
    head -n 1
)"

for tool in "$aapt" "$zipalign" "$readelf"; do
  if [[ ! -x "$tool" ]]; then
    echo "Required Android tool is unavailable: $tool" >&2
    exit 127
  fi
done

badging="$("$aapt" dump badging "$apk")"
grep -F "package: name='com.sl.autobook'" <<< "$badging" > /dev/null
grep -F "sdkVersion:'26'" <<< "$badging" > /dev/null
grep -F "targetSdkVersion:'36'" <<< "$badging" > /dev/null

expected_abis="$(printf '%s\n' arm64-v8a armeabi-v7a x86_64 | sort)"
apk_abis="$(
  unzip -Z1 "$apk" |
    sed -n 's#^lib/\([^/]*\)/[^/]*\.so$#\1#p' |
    sort -u
)"
aab_abis="$(
  unzip -Z1 "$aab" |
    sed -n 's#^base/lib/\([^/]*\)/[^/]*\.so$#\1#p' |
    sort -u
)"

if [[ "$apk_abis" != "$expected_abis" || "$aab_abis" != "$expected_abis" ]]; then
  echo "Unexpected Android ABI set." >&2
  printf 'Expected:\n%s\nAPK:\n%s\nAAB:\n%s\n' \
    "$expected_abis" "$apk_abis" "$aab_abis" >&2
  exit 1
fi

apk_libraries="$(
  unzip -Z1 "$apk" |
    sed -n 's#^lib/[^/]*/\([^/]*\.so\)$#\1#p' |
    sort -u
)"
aab_libraries="$(
  unzip -Z1 "$aab" |
    sed -n 's#^base/lib/[^/]*/\([^/]*\.so\)$#\1#p' |
    sort -u
)"

if [[ -z "$apk_libraries" || "$apk_libraries" != "$aab_libraries" ]]; then
  echo "APK and AAB native library sets do not match." >&2
  exit 1
fi

for abi in arm64-v8a armeabi-v7a x86_64; do
  apk_abi_libraries="$(
    unzip -Z1 "$apk" |
      sed -n "s#^lib/$abi/\([^/]*\.so\)\$#\1#p" |
      sort -u
  )"
  aab_abi_libraries="$(
    unzip -Z1 "$aab" |
      sed -n "s#^base/lib/$abi/\([^/]*\.so\)\$#\1#p" |
      sort -u
  )"
  if [[ "$apk_abi_libraries" != "$apk_libraries" || "$aab_abi_libraries" != "$aab_libraries" ]]; then
    echo "Native libraries are incomplete for $abi." >&2
    exit 1
  fi
done

temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT

check_elf_alignment() {
  local archive="$1"
  local prefix="$2"
  local count=0

  while IFS= read -r entry; do
    [[ -n "$entry" ]] || continue
    count=$((count + 1))
    unzip -p "$archive" "$entry" > "$temp_dir/library.so"
    mapfile -t alignments < <("$readelf" -lW "$temp_dir/library.so" | awk '$1 == "LOAD" {print $NF}')
    if [[ ${#alignments[@]} -eq 0 ]]; then
      echo "No ELF LOAD segments found in $entry." >&2
      exit 1
    fi
    for alignment in "${alignments[@]}"; do
      if [[ ! "$alignment" =~ ^0x[0-9a-fA-F]+$ ]] || (( alignment < 0x4000 )); then
        echo "$entry is not 16 KB ELF-aligned: $alignment" >&2
        exit 1
      fi
    done
  done < <(unzip -Z1 "$archive" | sed -n "\\#^$prefix/.*/.*\\.so\$#p")

  if [[ $count -eq 0 ]]; then
    echo "No native libraries found in $archive." >&2
    exit 1
  fi
}

check_elf_alignment "$apk" lib
check_elf_alignment "$aab" base/lib
"$zipalign" -c -P 16 -v 4 "$apk" > /dev/null
java -jar "$BUNDLETOOL_JAR" validate --bundle="$aab"
java -jar "$BUNDLETOOL_JAR" dump config --bundle="$aab" |
  grep -F 'PAGE_ALIGNMENT_16K' > /dev/null

echo "Android release artifacts satisfy SDK, ABI, and 16 KB page-size requirements."
