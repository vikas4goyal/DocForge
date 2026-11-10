import 'package:doc_scanly/features/cloud_storage/application/usecases/resolve_storage_decision.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_availability.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_decision.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:flutter_test/flutter_test.dart';

const _policy = ResolveStorageDecision();

StorageMigrationCheckpoint _checkpoint(
  StorageMigrationPhase phase, {
  StorageLocation destination = StorageLocation.iCloud,
}) => StorageMigrationCheckpoint(
  source: destination == StorageLocation.iCloud
      ? StorageLocation.local
      : StorageLocation.iCloud,
  destination: destination,
  phase: phase,
);

const _unavailableStatuses = [
  CloudAvailabilityStatus.signedOut,
  CloudAvailabilityStatus.disabled,
  CloudAvailabilityStatus.restricted,
  CloudAvailabilityStatus.unavailable,
];

void main() {
  group('without a checkpoint', () {
    for (final stored in [null, StorageLocation.local]) {
      group('stored ${stored?.id ?? 'absent'}', () {
        for (final hasPayloads in [false, true]) {
          for (final status in _unavailableStatuses) {
            test('falls back to the device when ${status.name} '
                '(payloads: $hasPayloads)', () {
              expect(
                _policy(
                  StorageDecisionInputs(
                    stored: stored,
                    availability: status,
                    marker: CloudMarkerState.absent,
                    localHasPayloads: hasPayloads,
                  ),
                ),
                StorageDecision.useLocal(reason: status),
              );
            });
          }
        }

        test('an empty device adopts iCloud and writes a missing marker', () {
          expect(
            _policy(
              StorageDecisionInputs(
                stored: stored,
                availability: CloudAvailabilityStatus.available,
                marker: CloudMarkerState.absent,
                localHasPayloads: false,
              ),
            ),
            const StorageDecision.useICloud(writeMarker: true),
          );
        });

        test('an empty device adopts an established library as is', () {
          expect(
            _policy(
              StorageDecisionInputs(
                stored: stored,
                availability: CloudAvailabilityStatus.available,
                marker: CloudMarkerState.supported,
                localHasPayloads: false,
              ),
            ),
            const StorageDecision.useICloud(),
          );
        });

        for (final marker in [
          CloudMarkerState.absent,
          CloudMarkerState.supported,
        ]) {
          test('a device library migrates (marker ${marker.name})', () {
            expect(
              _policy(
                StorageDecisionInputs(
                  stored: stored,
                  availability: CloudAvailabilityStatus.available,
                  marker: marker,
                  localHasPayloads: true,
                ),
              ),
              const StorageDecision.migrateToICloud(),
            );
          });
        }

        for (final hasPayloads in [false, true]) {
          test('an unsupported marker keeps the device authoritative '
              '(payloads: $hasPayloads)', () {
            expect(
              _policy(
                StorageDecisionInputs(
                  stored: stored,
                  availability: CloudAvailabilityStatus.available,
                  marker: CloudMarkerState.unsupported,
                  localHasPayloads: hasPayloads,
                ),
              ),
              const StorageDecision.useLocal(
                reason: CloudAvailabilityStatus.unavailable,
              ),
            );
          });

          test('continuing on the device holds for the session '
              '(payloads: $hasPayloads)', () {
            expect(
              _policy(
                StorageDecisionInputs(
                  stored: stored,
                  availability: CloudAvailabilityStatus.available,
                  marker: CloudMarkerState.absent,
                  localHasPayloads: hasPayloads,
                  continueLocalThisSession: true,
                ),
              ),
              const StorageDecision.useLocal(
                reason: CloudAvailabilityStatus.available,
              ),
            );
          });
        }
      });
    }

    group('stored iCloud', () {
      test('is used and repairs a missing marker', () {
        expect(
          _policy(
            const StorageDecisionInputs(
              stored: StorageLocation.iCloud,
              availability: CloudAvailabilityStatus.available,
              marker: CloudMarkerState.absent,
              localHasPayloads: true,
            ),
          ),
          const StorageDecision.useICloud(writeMarker: true),
        );
      });

      test('is used with its established marker', () {
        expect(
          _policy(
            const StorageDecisionInputs(
              stored: StorageLocation.iCloud,
              availability: CloudAvailabilityStatus.available,
              marker: CloudMarkerState.supported,
              localHasPayloads: false,
            ),
          ),
          const StorageDecision.useICloud(),
        );
      });

      for (final status in _unavailableStatuses) {
        for (final continueLocal in [false, true]) {
          test('never falls back when ${status.name} '
              '(continue local: $continueLocal)', () {
            expect(
              _policy(
                StorageDecisionInputs(
                  stored: StorageLocation.iCloud,
                  availability: status,
                  marker: CloudMarkerState.absent,
                  localHasPayloads: true,
                  continueLocalThisSession: continueLocal,
                ),
              ),
              StorageDecision.iCloudUnavailable(reason: status),
            );
          });
        }
      }
    });
  });

  group('with a checkpoint towards iCloud', () {
    for (final phase in [
      StorageMigrationPhase.copying,
      StorageMigrationPhase.verifying,
      StorageMigrationPhase.switching,
    ]) {
      test('resumes a pre-switch ${phase.name} while available', () {
        final checkpoint = _checkpoint(phase);
        expect(
          _policy(
            StorageDecisionInputs(
              stored: StorageLocation.local,
              availability: CloudAvailabilityStatus.available,
              marker: CloudMarkerState.absent,
              localHasPayloads: true,
              checkpoint: checkpoint,
            ),
          ),
          StorageDecision.migrateToICloud(resume: checkpoint),
        );
      });

      test('keeps the device for a pre-switch ${phase.name} when the user '
          'continued locally', () {
        expect(
          _policy(
            StorageDecisionInputs(
              stored: StorageLocation.local,
              availability: CloudAvailabilityStatus.available,
              marker: CloudMarkerState.absent,
              localHasPayloads: true,
              checkpoint: _checkpoint(phase),
              continueLocalThisSession: true,
            ),
          ),
          const StorageDecision.useLocal(
            reason: CloudAvailabilityStatus.available,
          ),
        );
      });

      test('keeps the device for a pre-switch ${phase.name} while signed '
          'out', () {
        expect(
          _policy(
            StorageDecisionInputs(
              stored: StorageLocation.local,
              availability: CloudAvailabilityStatus.signedOut,
              marker: CloudMarkerState.absent,
              localHasPayloads: true,
              checkpoint: _checkpoint(phase),
            ),
          ),
          const StorageDecision.useLocal(
            reason: CloudAvailabilityStatus.signedOut,
          ),
        );
      });
    }

    test('resumes cleanup even when the user asked to continue locally', () {
      final checkpoint = _checkpoint(StorageMigrationPhase.cleaning);
      expect(
        _policy(
          StorageDecisionInputs(
            stored: StorageLocation.iCloud,
            availability: CloudAvailabilityStatus.available,
            marker: CloudMarkerState.supported,
            localHasPayloads: true,
            checkpoint: checkpoint,
            continueLocalThisSession: true,
          ),
        ),
        StorageDecision.migrateToICloud(resume: checkpoint),
      );
    });

    test('reports a switched library as unavailable when iCloud is gone', () {
      expect(
        _policy(
          StorageDecisionInputs(
            stored: StorageLocation.iCloud,
            availability: CloudAvailabilityStatus.disabled,
            marker: CloudMarkerState.absent,
            localHasPayloads: true,
            checkpoint: _checkpoint(StorageMigrationPhase.cleaning),
          ),
        ),
        const StorageDecision.iCloudUnavailable(
          reason: CloudAvailabilityStatus.disabled,
        ),
      );
    });

    test('treats a switching checkpoint with stored iCloud as switched', () {
      expect(
        _policy(
          StorageDecisionInputs(
            stored: StorageLocation.iCloud,
            availability: CloudAvailabilityStatus.signedOut,
            marker: CloudMarkerState.supported,
            localHasPayloads: true,
            checkpoint: _checkpoint(StorageMigrationPhase.switching),
          ),
        ),
        const StorageDecision.iCloudUnavailable(
          reason: CloudAvailabilityStatus.signedOut,
        ),
      );
    });
  });

  test('ignores a legacy checkpoint towards the device', () {
    expect(
      _policy(
        StorageDecisionInputs(
          stored: StorageLocation.local,
          availability: CloudAvailabilityStatus.available,
          marker: CloudMarkerState.supported,
          localHasPayloads: true,
          checkpoint: _checkpoint(
            StorageMigrationPhase.cleaning,
            destination: StorageLocation.local,
          ),
        ),
      ),
      const StorageDecision.migrateToICloud(),
    );
  });
}
