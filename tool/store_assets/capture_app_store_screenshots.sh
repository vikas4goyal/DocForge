#!/usr/bin/env bash
# Captures App Store screenshots from the real app on iOS simulators.
#
# Drives integration_test/store_assets/app_store_screenshots_test.dart and
# takes a native simulator screenshot each time the test reports a screen as
# ready. Output (sizes Apple accepts as the required base sizes):
#   assets/store/app-store/screenshots/iphone-6.9/  1320x2868 (iPhone 17 Pro Max)
#   assets/store/app-store/screenshots/ipad-13/     2064x2752 (iPad Pro 13-inch M5)
# Dark-mode variants go to the same names with a `-dark` suffix.
#
# Usage: tool/store_assets/capture_app_store_screenshots.sh \
#          [iphone|ipad|iphone-dark|ipad-dark]...
# With no arguments, all four sets are captured.
set -euo pipefail

cd "$(dirname "$0")/../.."
ROOT="$PWD"
BUNDLE_ID="com.bruxkey.docscanly"
TEST="integration_test/store_assets/app_store_screenshots_test.dart"
OUT="$ROOT/assets/store/app-store/screenshots"

device_udid() {
  xcrun simctl list devices available -j | python3 -c '
import json, sys
name = sys.argv[1]
runtimes = json.load(sys.stdin)["devices"]
matches = [d["udid"] for r, ds in sorted(runtimes.items()) if "iOS" in r for d in ds if d["name"] == name]
print(matches[-1] if matches else "")' "$1"
}

capture() {
  local label="$1" name="$2" appearance="${3:-light}" udid dir log
  udid="$(device_udid "$name")"
  [[ -n "$udid" ]] || { echo "No available simulator named '$name'" >&2; return 1; }
  dir="$OUT/$label"
  mkdir -p "$dir"
  rm -f "$dir"/*.png
  # Captions are shared by the light and dark sets.
  local light_dir="$OUT/${label%-dark}"
  if [[ "$light_dir" != "$dir" ]]; then
    cp "$light_dir"/*.txt "$dir"/ 2>/dev/null || true
  fi

  echo "==> $label: $name ($udid)"
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b >/dev/null
  xcrun simctl ui "$udid" appearance "$appearance"
  xcrun simctl status_bar "$udid" override \
    --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 --operatorName "" \
    --batteryState charged --batteryLevel 100

  log="$(mktemp -t store_screens)"
  flutter test "$TEST" -d "$udid" --dart-define=STORE_SCREENSHOTS=true 2>&1 |
    tee "$log" |
    while IFS= read -r line; do
      echo "$line"
      if [[ "$line" =~ STORE_SCREENSHOT_READY:([A-Za-z0-9_-]+) ]]; then
        shot="${BASH_REMATCH[1]}"
        xcrun simctl io "$udid" screenshot --type=png "$dir/$shot.png" >/dev/null 2>&1
        echo "    captured $label/$shot.png"
        container="$(xcrun simctl get_app_container "$udid" "$BUNDLE_ID" data)"
        mkdir -p "$container/tmp"
        touch "$container/tmp/$shot.done"
      fi
    done
  grep -q "All tests passed" "$log" || { echo "Test run failed for $label; see $log" >&2; return 1; }
  xcrun simctl status_bar "$udid" clear
  xcrun simctl ui "$udid" appearance light
}

targets=("$@")
[[ ${#targets[@]} -gt 0 ]] || targets=(iphone ipad iphone-dark ipad-dark)
for target in "${targets[@]}"; do
  case "$target" in
    iphone) capture iphone-6.9 "iPhone 17 Pro Max" ;;
    ipad) capture ipad-13 "iPad Pro 13-inch (M5)" ;;
    iphone-dark) capture iphone-6.9-dark "iPhone 17 Pro Max" dark ;;
    ipad-dark) capture ipad-13-dark "iPad Pro 13-inch (M5)" dark ;;
    *) echo "Unknown target: $target" >&2; exit 2 ;;
  esac
done
echo "Screenshots written to $OUT"
