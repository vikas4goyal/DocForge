#!/usr/bin/env bash
# Renders the app icon and launch-screen bitmaps from the SVG sources in
# assets/store/source/ with headless Chrome, then scales them with sips.
#
#   bash tool/store_assets/generate_launch_assets.sh
#
# Outputs:
#   assets/store/docscanly-app-icon-{1024,512}.png   store icon
#   ios/.../AppIcon.appiconset/*.png                  every iOS icon size
#   ios/.../LaunchLogo.imageset/*.png                 launch glyph, 180pt
#   ios/.../LaunchGradient.imageset/*.png             launch background
#   android/.../mipmap-*/ic_launcher.png              launcher icon
#   android/.../drawable-*/launch_logo.png            pre-Android 12 splash glyph
#   android/.../drawable-*/splash_icon.png            Android 12+ splash icon
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$ROOT/assets/store/source"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# render <svg> <width> <height> <out.png> [transparent]
render() {
  local svg="$1" w="$2" h="$3" out="$4" bg=()
  [[ "${5:-}" == transparent ]] && bg=(--default-background-color=00000000)
  # Resize the root <svg> only: shapes inside use width/height too.
  sed -E "/<svg /s/ width=\"[0-9]+\" height=\"[0-9]+\"/ width=\"$w\" height=\"$h\"/" "$svg" >"$TMP/in.svg"
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars ${bg[@]+"${bg[@]}"} \
    --window-size="$w,$h" --screenshot="$out" "file://$TMP/in.svg" 2>/dev/null
}

# --- App icon -----------------------------------------------------------------
render "$SRC/docscanly-app-icon.svg" 1024 1024 "$TMP/icon.png"
cp "$TMP/icon.png" "$ROOT/assets/store/docscanly-app-icon-1024.png"
sips -Z 512 "$TMP/icon.png" --out "$ROOT/assets/store/docscanly-app-icon-512.png" >/dev/null
for f in "$ROOT"/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png; do
  spec="$(basename "$f" .png)"; spec="${spec#Icon-App-}"
  pt="${spec%%x*}"; scale="${spec##*@}"; scale="${scale%x}"
  sips -Z "$(python3 -c "print(round($pt*$scale))")" "$TMP/icon.png" --out "$f" >/dev/null
done
for d in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
  sips -Z "${d#*:}" "$TMP/icon.png" \
    --out "$ROOT/android/app/src/main/res/mipmap-${d%:*}/ic_launcher.png" >/dev/null
done

# --- iOS launch screen --------------------------------------------------------
LOGO="$ROOT/ios/Runner/Assets.xcassets/LaunchLogo.imageset"
render "$SRC/docscanly-launch-glyph.svg" 540 540 "$TMP/glyph.png" transparent
cp "$TMP/glyph.png" "$LOGO/LaunchLogo@3x.png"
sips -Z 360 "$TMP/glyph.png" --out "$LOGO/LaunchLogo@2x.png" >/dev/null
sips -Z 180 "$TMP/glyph.png" --out "$LOGO/LaunchLogo.png" >/dev/null
render "$SRC/docscanly-launch-background.svg" 390 844 \
  "$ROOT/ios/Runner/Assets.xcassets/LaunchGradient.imageset/LaunchGradient.png"

# --- Android splash -----------------------------------------------------------
RES="$ROOT/android/app/src/main/res"
render "$SRC/docscanly-launch-glyph.svg" 720 720 "$TMP/glyph-big.png" transparent
# Android 12+ masks the splash icon to a 192dp circle on a 288dp canvas, so the
# glyph is padded to sit at 150dp, clear of the mask.
sed 's/viewBox="150 150 724 724"/viewBox="-183 -183 1390 1390"/' \
  "$SRC/docscanly-launch-glyph.svg" >"$TMP/splash.svg"
render "$TMP/splash.svg" 1152 1152 "$TMP/splash.png" transparent
# Lossy WebP with alpha keeps the five densities to a fraction of the PNG size;
# every splash byte ships in the APK.
for d in mdpi:1 hdpi:1.5 xhdpi:2 xxhdpi:3 xxxhdpi:4; do
  dir="$RES/drawable-${d%:*}"
  mkdir -p "$dir"
  sips -Z "$(python3 -c "print(round(180*${d#*:}))")" "$TMP/glyph-big.png" --out "$TMP/l.png" >/dev/null
  cwebp -quiet -q 88 -alpha_q 90 "$TMP/l.png" -o "$dir/launch_logo.webp"
  sips -Z "$(python3 -c "print(round(288*${d#*:}))")" "$TMP/splash.png" --out "$TMP/s.png" >/dev/null
  cwebp -quiet -q 88 -alpha_q 90 "$TMP/s.png" -o "$dir/splash_icon.webp"
done

echo "launch and icon assets written"
