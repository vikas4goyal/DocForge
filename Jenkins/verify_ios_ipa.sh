#!/bin/sh

# Reject distribution artifacts that cannot initialize Isar through
# DynamicLibrary.process(). Xcode can retain the static archive at link time
# and then remove its global exports while post-processing the .xcarchive.
set -eu

set -- build/ios/ipa/*.ipa
if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
  echo "Expected exactly one IPA under build/ios/ipa." >&2
  ls -la build/ios/ipa >&2 || true
  exit 1
fi
ipa_path=$1

verification_dir=$(mktemp -d "${TMPDIR:-/tmp}/docscanly-ipa.XXXXXX")
trap 'rm -rf "$verification_dir"' EXIT

info_entry=$(unzip -Z1 "$ipa_path" | awk '/^Payload\/[^\/]+\.app\/Info\.plist$/ { print; exit }')
if [ -z "$info_entry" ]; then
  echo "Could not locate the application Info.plist inside $ipa_path." >&2
  exit 1
fi

unzip -p "$ipa_path" "$info_entry" > "$verification_dir/Info.plist"
executable=$(plutil -extract CFBundleExecutable raw "$verification_dir/Info.plist")
app_entry=${info_entry%/Info.plist}
unzip -p "$ipa_path" "$app_entry/$executable" > "$verification_dir/AppExecutable"

isar_exports=$(xcrun dyld_info -exports "$verification_dir/AppExecutable" |
  awk '/_isar_/ { count++ } END { print count + 0 }')
if [ "$isar_exports" -lt 90 ]; then
  echo "IPA verification failed: found only $isar_exports Isar exports; expected at least 90." >&2
  exit 1
fi

echo "IPA verification passed: $isar_exports Isar exports retained in $executable."
