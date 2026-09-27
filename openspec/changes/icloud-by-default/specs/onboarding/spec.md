## MODIFIED Requirements

### Requirement: Privacy and offline introduction
The Privacy & Offline Introduction screen SHALL state truthfully where documents are stored and what leaves the device, and that scanning and OCR work without an internet connection. On Android it SHALL state that documents are stored only on the device and that no document is uploaded automatically. On iOS, where the library is kept in the user's own iCloud Drive whenever iCloud is on, it SHALL state that documents are kept in the user's own iCloud Drive when iCloud is on and otherwise only on the device, and that nothing is sent to DocScanly servers.

#### Scenario: Privacy statements are presented
- **WHEN** the Privacy & Offline Introduction screen is displayed
- **THEN** it shows the storage statement (`onboarding_privacy_local_storage`), the upload statement (`onboarding_privacy_no_upload`) and the offline-capability statement
- **AND** each statement is exposed to screen readers with a descriptive semantics label

#### Scenario: Android states device-only storage
- **WHEN** the screen is displayed on Android
- **THEN** the storage statement reads “Your documents are stored only on this device.” and the upload statement reads “Nothing is uploaded automatically. You choose what to share.”

#### Scenario: iOS states iCloud storage
- **WHEN** the screen is displayed on iOS
- **THEN** the storage statement reads “Your documents are kept in your own iCloud Drive when iCloud is on, otherwise only on this device.” and the upload statement reads “Nothing is sent to DocScanly servers — we don’t have any.”
- **AND** neither device-only promise is shown
