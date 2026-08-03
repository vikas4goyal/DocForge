import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/trash.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final deletedAt = DateTime.utc(2026, 8, 3, 10);
  final entry = TrashEntry(
    id: const TrashId('trash-1'),
    kind: TrashEntryKind.folderTree,
    displayName: 'Invoices',
    originalRelativePath: 'Work/Invoices',
    deletedAt: deletedAt,
    expiresAt: TrashEntry.expiryFor(deletedAt),
    inventory: const TrashInventory(
      documentCount: 2,
      otherFileCount: 1,
      folderCount: 3,
      sizeInBytes: 42,
    ),
    documentIds: const [DocumentId('doc-1'), DocumentId('doc-2')],
  );

  test('round-trips every Trash field through JSON', () {
    expect(TrashEntry.fromJson(entry.toJson()), entry);
    expect(entry.inventory.fileCount, 3);
    expect(entry.inventory.hasChildren, isTrue);
  });

  test('expires exactly at the thirty-day boundary', () {
    expect(
      entry.isExpiredAt(
        entry.expiresAt.subtract(const Duration(microseconds: 1)),
      ),
      isFalse,
    );
    expect(entry.isExpiredAt(entry.expiresAt), isTrue);
  });

  test('recovered names are deterministic and preserve extensions', () {
    final taken = {'Invoice.pdf', 'Invoice (Recovered 1).pdf'};
    expect(
      recoveredName('Invoice.pdf', taken.contains),
      'Invoice (Recovered 2).pdf',
    );
    expect(
      recoveredName('Folder', (name) => name == 'Folder'),
      'Folder (Recovered 1)',
    );
  });
}
