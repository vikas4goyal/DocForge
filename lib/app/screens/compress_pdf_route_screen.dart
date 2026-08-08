/// Composition host for the typed Compress PDF route.
library;

import 'dart:io';

import 'package:doc_scanly/app/router/app_routes.dart';
import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/pdf_quality.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/jobs/pdf_jobs.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/document_file_resolver.dart';
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/core/widgets/app_state_views.dart';
import 'package:doc_scanly/features/pdf_editing/application/usecases/compression_workflow.dart';
import 'package:doc_scanly/features/pdf_editing/domain/compression_candidate.dart';
import 'package:doc_scanly/features/pdf_editing/domain/repositories/pdf_editor_repository.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/cubit/compress_pdf_cubit.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/screens/compress_pdf_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Loads route inputs and owns candidate/source cleanup for Compress PDF.
class CompressPdfRouteScreen extends StatefulWidget {
  /// Creates the composition host.
  const CompressPdfRouteScreen({
    required this.documentId,
    required this.documents,
    required this.writer,
    required this.rollbackCopy,
    required this.restoreMetadata,
    required this.store,
    required this.files,
    required this.secrets,
    required this.candidateRepository,
    required this.workingDirectory,
    required this.clock,
    required this.ids,
    super.key,
  });

  /// Source identity from the typed route.
  final DocumentId documentId;

  /// Loads source metadata and page rows.
  final DocumentReader documents;

  /// Persists copy or overwrite metadata.
  final DocumentWriter writer;

  /// Removes a partially recorded copy.
  final RollbackCompressionCopy rollbackCopy;

  /// Restores original metadata during overwrite rollback.
  final RestoreCompressionMetadata restoreMetadata;

  /// Publishes authoritative bytes.
  final PublicFileStore store;

  /// Materializes and releases source bytes.
  final DocumentFileResolver files;

  /// Reads an existing protected source credential.
  final SecureStore secrets;

  /// Creates one candidate owner for this route.
  final CompressionCandidateRepository Function() candidateRepository;

  /// App-private staging location.
  final Directory workingDirectory;

  /// Supplies deterministic metadata timestamps.
  final Clock clock;

  /// Supplies copy, page, and staging identifiers.
  final IdGenerator ids;

  @override
  State<CompressPdfRouteScreen> createState() => _CompressPdfRouteScreenState();
}

class _CompressPdfRouteScreenState extends State<CompressPdfRouteScreen> {
  CompressPdfCubit? _cubit;
  CompressionCandidateRepository? _repository;
  CompressionCandidateCache? _cache;
  Document? _source;
  Failure? _failure;
  String? _sourcePath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final found = await widget.documents.findById(widget.documentId);
    if (found case Failed(:final failure)) return _fail(failure);
    final source = found.valueOrNull!;
    final resolved = await widget.files.pathFor(source);
    if (resolved case Failed(:final failure)) return _fail(failure);
    final path = resolved.valueOrNull!;
    final pages = await widget.documents.pagesOf(source.id);
    if (pages case Failed(:final failure)) {
      await widget.files.release(source);
      return _fail(failure);
    }
    String? password;
    if (source.isProtected) {
      final read = await widget.secrets.read(
        SecureStorageKeys.pdfPassword(source.id.value),
      );
      if (read case Failed(:final failure)) {
        await widget.files.release(source);
        return _fail(failure);
      }
      password = read.valueOrNull;
      if (password == null) {
        await widget.files.release(source);
        return _fail(const Failure.auth(debugDetail: 'pdf_password_required'));
      }
    }
    if (!mounted) {
      await widget.files.release(source);
      return;
    }

    final repository = widget.candidateRepository();
    final cache = CompressionCandidateCache();
    final file = File(path);
    final sourceIdentity =
        '${source.id.value}:${source.sizeInBytes}:${source.updatedAt.toUtc().toIso8601String()}:${file.existsSync() ? file.lastModifiedSync().toUtc().toIso8601String() : 'missing'}';
    CompressionWorkflowRequest requestFactory({
      required PageQualityPlan qualityPlan,
      required CompressionDestination? destination,
    }) => CompressionWorkflowRequest(
      source: source,
      sourcePages: pages.valueOrNull ?? const <DocumentPage>[],
      draft: CompressionDraft(
        sourceDocumentId: source.id.value,
        pageCount: source.pageCount,
        originalBytes: source.sizeInBytes,
        qualityPlan: qualityPlan,
        destination: destination,
      ),
      candidateRequest: CompressionCandidateRequest(
        sourcePath: path,
        pageCount: source.pageCount,
        qualityPlan: qualityPlan,
        fingerprint: PdfCandidateFingerprint(
          sourceIdentity: sourceIdentity,
          configurationIdentity: qualityPlan.toJson().toString(),
          orderedPageQualities: <int>[
            for (var index = 0; index < source.pageCount; index++)
              qualityPlan.effectiveFor('$index').value,
          ],
          isProtected: password != null,
        ),
        password: password,
      ),
    );
    final cubit = CompressPdfCubit(
      title: source.title,
      pageCount: source.pageCount,
      originalBytes: source.sizeInBytes,
      calculate: CalculateCompressedSize(repository, cache),
      preparePreview: PrepareCompressionPreview(repository, cache),
      save: SaveCompressedPdf(
        repository: repository,
        cache: cache,
        documents: widget.writer,
        rollbackCopy: widget.rollbackCopy,
        restoreMetadata: widget.restoreMetadata,
        store: widget.store,
        secrets: widget.secrets,
        clock: widget.clock,
        ids: widget.ids,
        workingDirectory: widget.workingDirectory,
      ),
      requestFactory: requestFactory,
    );
    setState(() {
      _source = source;
      _sourcePath = path;
      _repository = repository;
      _cache = cache;
      _cubit = cubit;
    });
    await cubit.load();
  }

  void _fail(Failure failure) {
    if (mounted) setState(() => _failure = failure);
  }

  @override
  void dispose() {
    final cubit = _cubit;
    if (cubit != null) cubit.close();
    final cache = _cache;
    final repository = _repository;
    if (cache != null && repository != null) cache.dispose(repository);
    final source = _source;
    if (source != null && _sourcePath != null) widget.files.release(source);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final failure = _failure;
    if (failure != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compress PDF')),
        body: AppErrorView(
          failure: failure,
          onRetry: () {
            setState(() => _failure = null);
            _load();
          },
        ),
      );
    }
    final cubit = _cubit;
    if (cubit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compress PDF')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return CompressPdfScreen(
      cubit: cubit,
      onOpenPreview: (handle) {
        final route = PdfTemporaryPreviewRoute(candidateHandle: handle);
        context.push<void>(route.location, extra: route);
      },
      onCompleted: (result) {
        context.pop(
          CompressPdfCompletion(
            kind: result.destination == CompressionDestination.copy
                ? CompressPdfCompletionKind.openCopy
                : CompressPdfCompletionKind.refreshOriginal,
            documentId: DocumentId(result.documentId),
          ),
        );
      },
    );
  }
}
