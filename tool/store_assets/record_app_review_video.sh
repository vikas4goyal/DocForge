#!/usr/bin/env bash
# Records an App Review demo video of the real app on an iOS simulator.
#
# Drives integration_test/store_assets/app_review_video_test.dart, starts
# `simctl io recordVideo` when the test is ready to launch the app, and stops
# when the test reports it has finished. Output:
#   assets/store/app-store/video/app-review-demo.mp4
#
# Usage: tool/store_assets/record_app_review_video.sh ["Simulator name"]
set -euo pipefail

cd "$(dirname "$0")/../.."
ROOT="$PWD"
BUNDLE_ID="com.bruxkey.docscanly"
TEST="integration_test/store_assets/app_review_video_test.dart"
NAME="${1:-iPhone 17 Pro Max}"
OUT_DIR="$ROOT/assets/store/app-store/video"
RAW="$OUT_DIR/app-review-demo.raw.mov"
OUT="$OUT_DIR/app-review-demo.mp4"

udid="$(xcrun simctl list devices available -j | python3 -c '
import json, sys
name = sys.argv[1]
runtimes = json.load(sys.stdin)["devices"]
matches = [d["udid"] for r, ds in sorted(runtimes.items()) if "iOS" in r for d in ds if d["name"] == name]
print(matches[-1] if matches else "")' "$NAME")"
[[ -n "$udid" ]] || { echo "No available simulator named '$NAME'" >&2; exit 1; }

mkdir -p "$OUT_DIR"
rm -f "$RAW" "$OUT"

echo "==> $NAME ($udid)"
xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b >/dev/null
open -a Simulator --args -CurrentDeviceUDID "$udid"
xcrun simctl ui "$udid" appearance light
xcrun simctl status_bar "$udid" override \
  --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --operatorName "" \
  --batteryState charged --batteryLevel 100
# A fresh install, so the recording shows first-launch onboarding.
xcrun simctl uninstall "$udid" "$BUNDLE_ID" 2>/dev/null || true

log="$(mktemp -t store_video)"
# `flutter drive` rather than `flutter test`: the test installs its own binding
# (to hide touch crosshairs), which `flutter test` would have initialised first.
flutter drive --driver test_driver/integration_test.dart --target "$TEST" \
  -d "$udid" --dart-define=STORE_VIDEO=true 2>&1 |
  tee "$log" |
  while IFS= read -r line; do
    echo "$line"
    if [[ "$line" == *STORE_VIDEO_READY* ]]; then
      xcrun simctl io "$udid" recordVideo --codec=h264 --force "$RAW" &
      echo $! >"$log.pid"
      sleep 2
      container="$(xcrun simctl get_app_container "$udid" "$BUNDLE_ID" data)"
      mkdir -p "$container/tmp"
      touch "$container/tmp/video.started"
      echo "    recording started"
    elif [[ "$line" == *STORE_VIDEO_DONE* ]]; then
      sleep 2
      kill -INT "$(cat "$log.pid")" 2>/dev/null || true
      echo "    recording stopped"
    fi
  done
# The recorder may still be flushing.
if [[ -f "$log.pid" ]]; then
  pid="$(cat "$log.pid")"
  while kill -0 "$pid" 2>/dev/null; do sleep 0.5; done
fi

grep -q "All tests passed" "$log" || { echo "Test run failed; see $log" >&2; exit 1; }
xcrun simctl status_bar "$udid" clear

# H.264, even dimensions, web-friendly, well under App Store Connect limits.
ffmpeg -y -loglevel error -i "$RAW" \
  -vf "scale=-2:1920,fps=30" -c:v libx264 -preset slow -crf 23 \
  -pix_fmt yuv420p -movflags +faststart -an "$OUT"
rm -f "$RAW"
echo "Video written to $OUT"
