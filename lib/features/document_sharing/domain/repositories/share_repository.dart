/// The seams between this feature and the platform's sharing facilities.
///
/// Three separate interfaces rather than one, because they fail in different
/// ways and are substituted independently: a test for the export path has no
/// interest in the print dialogue, and the print dialogue is the one facility
/// that reports a user cancellation as a normal result.
library;

import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_sharing/domain/share_content.dart';

/// Hands prepared content to the system share sheet.
abstract interface class ShareRepository {
  /// Opens the share sheet with [payload] attached.
  ///
  /// Fails with an export failure carrying `noReceivingApp` when the system
  /// reports that nothing can handle the content, which the specs answer by
  /// offering export to device storage instead.
  Future<Result<void>> share(SharePayload payload);
}

/// Opens the system print dialogue.
abstract interface class PrintRepository {
  /// Prints the PDF at [filePath] under [jobName].
  ///
  /// Returns true when the job was submitted and false when the user cancelled
  /// the dialogue. Cancellation is a successful result rather than a failure:
  /// the spec requires the application to return to the previous screen with no
  /// change and no message, and an error path would produce a message.
  Future<Result<bool>> printFile(String filePath, {required String jobName});
}

/// Asks the user where an exported file should be written.
abstract interface class ExportDestinationPicker {
  /// Offers a destination picker seeded with [suggestedName].
  ///
  /// Returns the chosen absolute path, or null when the user cancelled. As with
  /// printing, cancellation is a successful null rather than a failure, because
  /// nothing went wrong and nothing should be said about it.
  ///
  /// [initialDirectory] is the user's configured default save location, when
  /// they have one.
  Future<Result<String?>> chooseDestination({
    required String suggestedName,
    String? initialDirectory,
  });
}
