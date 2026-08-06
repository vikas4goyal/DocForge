import 'package:doc_scanly/features/document_library/domain/library_display_density.dart';
import 'package:doc_scanly/features/document_library/presentation/library_grid_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compact widths use exactly two columns at normal text scale', () {
    expect(LibraryGridLayout.columnsFor(availableWidth: 320, textScale: 1), 2);
    expect(
      LibraryGridLayout.columnsFor(availableWidth: 599.999, textScale: 1),
      2,
    );
  });

  test('wide widths derive at least three readable columns', () {
    expect(LibraryGridLayout.columnsFor(availableWidth: 600, textScale: 1), 3);
    expect(LibraryGridLayout.columnsFor(availableWidth: 1024, textScale: 1), 5);
  });

  test('split-view resize is deterministic at exact breakpoints', () {
    expect(LibraryGridLayout.columnsFor(availableWidth: 768, textScale: 1), 3);
    expect(
      LibraryGridLayout.columnsFor(availableWidth: 599.999, textScale: 1),
      2,
    );
  });

  test('large text has a one-column compact fallback', () {
    expect(
      LibraryGridLayout.columnsFor(availableWidth: 479.999, textScale: 2),
      1,
    );
    expect(LibraryGridLayout.columnsFor(availableWidth: 480, textScale: 2), 2);
  });

  test('tile extent remains stable across every layout branch', () {
    expect(LibraryGridLayout.tileExtent, 286);
    expect(LibraryGridLayout.smallTileExtent, 218);
  });

  test('small density uses three phone columns and denser wide columns', () {
    expect(
      LibraryGridLayout.columnsFor(
        availableWidth: 390,
        textScale: 1,
        density: LibraryDisplayDensity.small,
      ),
      3,
    );
    expect(
      LibraryGridLayout.columnsFor(
        availableWidth: 1024,
        textScale: 1,
        density: LibraryDisplayDensity.small,
      ),
      7,
    );
  });
}
