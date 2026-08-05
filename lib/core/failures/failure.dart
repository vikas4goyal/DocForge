/// The single error vocabulary shared by every layer of DocScanly.
///
/// Exceptions never cross a layer boundary in this project. A repository or use
/// case that cannot complete returns a [Failure] instead, which makes every
/// error path visible in the type system and forces the presentation layer to
/// account for each one. The specs require a clear message and a recovery
/// action for every failure, and an exhaustive sealed union is what makes it
/// impossible to add a new failure without also deciding what the user sees.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// Why a permission-related operation could not proceed.
enum PermissionKind {
  /// Access to the device camera.
  camera,

  /// Access to the photo library.
  photos,

  /// Access to device files.
  files,
}

/// Why user-supplied input was rejected.
///
/// Distinct from the technical failures below: nothing went wrong, the input
/// simply cannot be accepted, and the user can correct it in place. Kept in
/// `core` rather than in the library feature because naming rules apply to
/// scanning, import and settings too.
enum ValidationIssue {
  /// A title or folder name was empty or contained only whitespace.
  emptyName,

  /// A folder with the same name already exists.
  duplicateFolderName,

  /// The operation would leave a document with no pages.
  documentWouldHaveNoPages,

  /// A name contained characters that cannot be used on disk.
  ///
  /// Distinct from [emptyName] because the fix is different: the user has to
  /// change a character rather than type something. Now that documents live in
  /// a folder the user can also reach from the file browser, a name has to be
  /// legal on both platforms' filesystems, not merely non-empty.
  illegalName,

  /// A document with the same name already exists in the target folder.
  duplicateDocumentName,

  /// A password and its confirmation did not match.
  passwordMismatch,

  /// A destructive bulk action was submitted without its reviewed confirmation.
  bulkActionNotConfirmed,
}

/// Every way an operation in DocScanly can fail.
///
/// Variants carry only what a caller needs in order to recover or to explain
/// the problem. Technical detail useful for diagnosis goes in each variant's
/// `debugDetail` field, which is never shown to the user.
@freezed
sealed class Failure with _$Failure {
  /// The camera could not be opened, initialised or used.
  const factory Failure.camera({
    /// True when another application currently holds the camera.
    @Default(false) bool inUseByAnotherApp,
    String? debugDetail,
  }) = CameraFailure;

  /// A required permission was refused.
  const factory Failure.permission({
    required PermissionKind kind,

    /// True when the user chose "don't ask again", so only the system settings
    /// screen can resolve it. This is the difference between offering a retry
    /// and offering to open settings.
    @Default(false) bool permanentlyDenied,
    String? debugDetail,
  }) = PermissionFailure;

  /// Text recognition failed for a page.
  ///
  /// Never fatal to document creation: the specs require a PDF to be produced
  /// without a text layer rather than the save being blocked.
  const factory Failure.ocr({String? debugDetail}) = OcrFailure;

  /// A PDF could not be generated, read or modified.
  const factory Failure.pdf({String? debugDetail}) = PdfFailure;

  /// The device ran out of storage part-way through an operation.
  const factory Failure.storageFull({String? debugDetail}) = StorageFullFailure;

  /// Content could not be imported.
  const factory Failure.import({
    /// True when the selected file is neither a supported image nor a PDF.
    @Default(false) bool unsupportedType,
    String? debugDetail,
  }) = ImportFailure;

  /// Content could not be exported, shared or printed.
  const factory Failure.export({
    /// True when the system reported that nothing can receive the shared
    /// content, which the specs answer by offering export instead.
    @Default(false) bool noReceivingApp,
    String? debugDetail,
  }) = ExportFailure;

  /// Authentication for the application lock failed or was unavailable.
  const factory Failure.auth({
    /// True when the user was rejected, false when the mechanism itself errored.
    @Default(true) bool rejected,

    /// True when the device has no biometric or device credential configured.
    @Default(false) bool notEnrolled,
    String? debugDetail,
  }) = AuthFailure;

  /// User-supplied input was rejected before anything was attempted.
  ///
  /// Carries the specific [issue] so the presentation layer can put the right
  /// message beside the offending field, rather than showing a screen-level
  /// error for something the user can fix by typing.
  const factory Failure.validation({
    required ValidationIssue issue,
    String? debugDetail,
  }) = ValidationFailure;

  /// The requested document, folder or page does not exist.
  const factory Failure.notFound({String? debugDetail}) = NotFoundFailure;

  /// A file exists but could not be parsed.
  const factory Failure.corruptFile({String? debugDetail}) = CorruptFileFailure;

  /// Secure storage could not be read or written.
  ///
  /// Kept distinct from [Failure.storage] because the recovery differs: a
  /// secret must never be written somewhere insecure as a fallback.
  const factory Failure.secureStorageUnavailable({String? debugDetail}) =
      SecureStorageFailure;

  /// A local storage read or write failed for a reason other than being full.
  const factory Failure.storage({String? debugDetail}) = StorageFailure;

  /// The operation was cancelled by the user.
  ///
  /// Modelled as a failure so callers must handle it explicitly, but it is not
  /// an error: the presentation layer shows no message for it.
  const factory Failure.cancelled() = CancelledFailure;

  /// An unanticipated error. Present so nothing is ever swallowed silently.
  const factory Failure.unexpected({String? debugDetail}) = UnexpectedFailure;

  const Failure._();

  /// Whether this failure represents deliberate user cancellation.
  ///
  /// Cancellation is the one failure the UI must not surface as an error, so
  /// this is checked rather than pattern-matched at every call site.
  bool get isCancellation => this is CancelledFailure;
}
