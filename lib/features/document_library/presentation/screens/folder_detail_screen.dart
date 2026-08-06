/// The contents of a single folder.
library;

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/features/document_library/presentation/library_keys.dart';
import 'package:doc_scanly/features/document_library/presentation/screens/document_list_screen.dart';
import 'package:doc_scanly/features/document_library/presentation/widgets/document_thumbnail.dart';
import 'package:flutter/material.dart';

/// Shows the documents inside one folder.
///
/// A thin wrapper over [DocumentListScreen] rather than its own list
/// implementation: the folder view differs only in its title, its empty-state
/// wording and the filter its Cubit was built with. Reimplementing the list
/// here would be a second place for loading, empty, error and pagination
/// behaviour to drift out of line with the spec.
///
/// The scoping filter lives in the list Cubit provided above this
/// widget, which is what keeps this screen free of any query logic.
class FolderDetailScreen extends StatelessWidget {
  /// Creates the folder contents screen for a folder named [folderName].
  const FolderDetailScreen({
    required this.folderName,
    required this.onOpenDocument,
    super.key,
    this.loadThumbnail,
  });

  /// Name of the folder being shown, used as the title.
  final String folderName;

  /// Called when a document row is activated.
  final void Function(DocumentId id) onOpenDocument;

  /// Lazily resolves first-page previews for visible document rows.
  final DocumentThumbnailLoader? loadThumbnail;

  @override
  Widget build(BuildContext context) {
    // Keyed and labelled here rather than inside [DocumentListScreen]: that
    // screen serves four routes, so its own key cannot say which one the user
    // is on. A flow that opened a folder and asserted on the list key alone
    // would pass without ever leaving the list it started from.
    return Semantics(
      key: LibraryKeys.folderDetailScreen,
      container: true,
      label: LibrarySemantics.folderDetailScreen(folderName),
      child: DocumentListScreen(
        title: folderName,
        onOpenDocument: onOpenDocument,
        loadThumbnail: loadThumbnail,
        emptyTitle: 'This folder is empty',
        emptyMessage: 'Move documents here to keep them together.',
      ),
    );
  }
}
