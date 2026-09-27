# DocScanly

DocScanly is an Android and iOS document scanner. Finished PDFs live in a
user-visible `DocScanly` library; derived thumbnails, recognised text, working
captures, preferences, and passwords remain private to each device.

## Storage by platform

- Android always uses the device-local MediaStore folder
  `Documents/DocScanly`. No iCloud channel, route, control, or background
  operation is constructed on Android.
- iOS uses the app-owned iCloud Documents container whenever it is available,
  without asking. A new install starts there and writes the library marker on
  first launch.
- An iOS device library with content (an upgraded install, or one started
  while iCloud was off) moves to iCloud automatically at the next cold launch.
  A migration gate runs *before* the library is composed, so nothing can write
  a document mid-move. On failure the gate offers **Retry** and **Continue on
  this device for now**; the next cold launch tries again. Settings → Storage
  location → **Move documents to iCloud now** rebuilds the app through the gate
  at once.
- While iCloud is unavailable (signed out, iCloud Drive off, DocScanly turned
  off in iOS Settings → iCloud, restricted, or temporarily unreachable) the
  library stays in `<app Documents>/DocScanly`, every feature works, and
  Settings → Storage location states the reason. To keep documents only on the
  device, turn DocScanly off in iOS Settings → iCloud; there is no in-app
  opt-out while iCloud is available.
- The iCloud document scope is presented by Files as `iCloud Drive/DocScanly`.
  Its actual root is the registered container’s `Documents` directory, so the
  app must not create another nested `DocScanly` folder there.
- A valid `.docscanly-library.json` marker lets a new iOS device signed into the
  same Apple Account discover an established library. Isar metadata does not
  sync; each device reconstructs its index from PDF/folder metadata.
- If an iCloud library that is already authoritative becomes unavailable,
  DocScanly shows a retry state and never silently falls back to a second
  local library. The user may explicitly, after confirmation, choose **Use this
  device without iCloud**: iCloud content is left untouched and the device
  library merges back when iCloud returns.
- Moving into an iCloud container that already holds a DocScanly library
  merges the two. Identical files are de-duplicated by digest; a different
  file at the same path is kept beside the original as
  `<name> (Conflict device).pdf` (then `(Conflict device 2)`, …). Reserved
  Trash payloads are never renamed, and the existing marker is kept.

## Apple configuration

The iOS target uses:

- Explicit App ID and bundle ID: `com.bruxkey.docscanly`
- iCloud container: `iCloud.com.bruxkey.docscanly`
- iCloud service: Documents (`CloudDocuments`)
- Public document-scope name: `DocScanly`

In Apple Developer, register the explicit App ID and container, assign the
container to the App ID, enable iCloud Documents, and regenerate development
and distribution provisioning profiles after changing capabilities. CloudKit
support and iCloud Extended Share Access are intentionally disabled; neither
entitlement belongs in `Runner.entitlements`.

Signing/profile registration is external to this repository. An unsigned
`xcodebuild` verifies compilation, but release verification still requires the
correct regenerated profile and a real-device smoke test against non-production
documents.

## Migration and recovery

Legacy device-local active/Trash trees from the retired app identity are
copied, verified, and cleaned into `DocScanly`. Location migration inventories
active and reserved Trash payloads, copies and stream-verifies each file,
durably checkpoints progress, switches authority only after verification, then
cleans the source.
Before the authority switch, cancellation rolls back only migration-owned
destination copies (and, when merging into an established library, only the
files that run wrote); after switching, cleanup resumes forward on retry.
The startup policy lives in `ResolveStorageDecision`, a pure function of the
stored authority, iCloud availability, marker, device-library content and any
checkpoint.

PDFs stored in iCloud download lazily when a thumbnail, viewer, editor, share,
print, or OCR operation needs bytes. Password-protected PDFs remain protected,
but their Keychain password is device-local and may need to be entered again on
a new device.

## Verification

Common local checks:

```sh
dart run build_runner build
flutter analyze
dart run tool/check_layering.dart
dart run tool/check_platforms.dart
dart run tool/check_branding.dart
flutter test
```

The full staged verifier is `dart run tool/verify.dart`. Device integration and
signed Debug/Release iOS checks are required before shipping; a skipped Tier 3
run is not release verification.
