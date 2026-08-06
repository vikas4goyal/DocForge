# DocScanly

DocScanly is an Android and iOS document scanner. Finished PDFs live in a
user-visible `DocScanly` library; derived thumbnails, recognised text, working
captures, preferences, and passwords remain private to each device.

## Storage by platform

- Android always uses the device-local MediaStore folder
  `Documents/DocScanly`. No iCloud channel, route, control, or background
  operation is constructed on Android.
- iOS defaults existing and new local libraries to `<app Documents>/DocScanly`.
  A user may explicitly move the authoritative PDF and Trash trees to the
  app-owned iCloud Documents container from Settings → Storage location.
- The iCloud document scope is presented by Files as `iCloud Drive/DocScanly`.
  Its actual root is the registered container’s `Documents` directory, so the
  app must not create another nested `DocScanly` folder there.
- A valid `.docscanly-library.json` marker lets a new iOS device signed into the
  same Apple Account discover an established library. Isar metadata does not
  sync; each device reconstructs its index from PDF/folder metadata.
- If a selected iCloud library is unavailable, DocScanly shows a retry state.
  It never silently falls back to a second local library.

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
destination copies; after switching, cleanup resumes forward on retry.

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
