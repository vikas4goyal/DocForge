# Spec Delta

## MODIFIED Requirements

### Requirement: End-to-end UI tests boot the real application

Tier‑3 tests SHALL launch the application through the same composition root that `main.dart` uses, substituting only services that sit at the platform edge — camera capture, edge detection, biometric authentication, the share sheet and the print dialog.

Every other dependency, including the router, all Cubits, all use cases, all repositories and real on-device storage, SHALL be the production implementation.

The test entrypoint used to supply substituted dependencies SHALL NOT be reachable from a release build, and production `main.dart` SHALL NOT import it.

#### Scenario: Flow starts from a cold app launch

- **WHEN** a Tier‑3 flow test begins
- **THEN** the application is built from the composition root with a supplied dependency bundle, and the widget tree is identical in structure to the one `main.dart` produces

#### Scenario: Real persistence is exercised

- **WHEN** a flow creates or modifies a document
- **THEN** the change is written through the production repository to real device storage, and a subsequent screen in the same flow reads it back through the production path

#### Scenario: Test seam is absent from production

- **WHEN** the layering check runs over `lib/`
- **THEN** it fails if `main.dart` transitively imports the test entrypoint or any fake platform service
