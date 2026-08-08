/// Composition host and private session registry for the typed Save PDF route.
library;

import 'dart:async';
import 'dart:io';

import 'package:doc_scanly/app/creation_module.dart';
import 'package:doc_scanly/app/router/app_routes.dart';
import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/page_render_plan.dart';
import 'package:doc_scanly/core/contracts/models/pdf_quality.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/jobs/pdf_jobs.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/core/widgets/app_state_views.dart';
import 'package:doc_scanly/features/document_creation/application/usecases/add_page.dart';
import 'package:doc_scanly/features/document_creation/application/usecases/render_page.dart';
import 'package:doc_scanly/features/pdf_generation/application/usecases/save_pdf_workflow.dart';
import 'package:doc_scanly/features/pdf_generation/domain/pdf_composition.dart';
import 'package:doc_scanly/features/pdf_generation/domain/repositories/pdf_repository.dart';
import 'package:doc_scanly/features/pdf_generation/presentation/cubit/save_pdf_cubit.dart';
import 'package:doc_scanly/features/pdf_generation/presentation/screens/save_pdf_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// App-private lookup from opaque route handles to creation-session snapshots.
class SavePdfSessionRegistry {
  final Map<String, CreationSaveSession> _sessions =
      <String, CreationSaveSession>{};

  /// Registers [session] and returns its opaque route handle.
  String register(CreationSaveSession session) {
    _sessions[session.sessionId] = session;
    return session.sessionId;
  }

  /// Resolves [handle] without exposing session values through route state.
  CreationSaveSession? resolve(String handle) => _sessions[handle];

  /// Releases a route handle after completion, cancellation, or disposal.
  void remove(String handle) => _sessions.remove(handle);
}

/// Loads a private creation session and owns its route-scoped PDF candidate.
class SavePdfRouteScreen extends StatefulWidget {
  /// Creates the Save PDF composition host.
  const SavePdfRouteScreen({
    required this.sessionHandle,
    required this.sessions,
    required this.renderPage,
    required this.initialQuality,
    required this.candidateRepository,
    required this.documents,
    required this.rollbackDocument,
    required this.store,
    required this.secrets,
    required this.clock,
    required this.ids,
    required this.workingDirectory,
    required this.discardSession,
    super.key,
  });

  /// Opaque session handle carried by [SavePdfRoute].
  final String sessionHandle;

  /// Composition-owned session registry.
  final SavePdfSessionRegistry sessions;

  /// Renders crop and enhancement layers at full output resolution.
  final RenderPage renderPage;

  /// Persisted default applied only when this route first opens.
  final PdfQualityPercent initialQuality;

  /// Creates the candidate owner scoped to this route.
  final GeneratedPdfCandidateRepository Function() candidateRepository;

  /// Commits document and page metadata.
  final DocumentWriter documents;

  /// Removes a partially committed record and its page rows.
  final RollbackGeneratedDocument rollbackDocument;

  /// Publishes authoritative PDF bytes.
  final PublicFileStore store;

  /// Stores a protection credential only after record commit.
  final SecureStore secrets;

  /// Supplies deterministic metadata time.
  final Clock clock;

  /// Supplies document and staging identifiers.
  final IdGenerator ids;

  /// App-private candidate and commit directory.
  final Directory workingDirectory;

  /// Deletes capture sources after verified completion only.
  final DiscardCreationSession discardSession;

  @override
  State<SavePdfRouteScreen> createState() => _SavePdfRouteScreenState();
}

class _SavePdfRouteScreenState extends State<SavePdfRouteScreen> {
  SavePdfCubit? _cubit;
  GeneratedPdfCandidateRepository? _repository;
  SavePdfCandidateCache? _cache;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = widget.sessions.resolve(widget.sessionHandle);
    if (session == null || session.pages.isEmpty) {
      _fail(const Failure.notFound(debugDetail: 'save_pdf_session_not_found'));
      return;
    }

    final preparedPaths = <String>[];
    for (final page in session.pages) {
      final rendered = await widget.renderPage(
        PageRenderPlan.of(page, scale: RenderScale.full),
        scope: session.sessionId,
      );
      if (rendered case Failed(:final failure)) {
        _fail(failure);
        return;
      }
      preparedPaths.add(rendered.valueOrNull!);
    }
    if (!mounted) return;

    final repository = widget.candidateRepository();
    final cache = SavePdfCandidateCache();
    SavePdfWorkflowRequest requestFactory({
      required String name,
      required PageQualityPlan qualityPlan,
      required String? password,
    }) {
      final orderedQualities = <int>[
        for (final page in session.pages)
          qualityPlan.effectiveFor(page.id.value).value,
      ];
      return SavePdfWorkflowRequest(
        title: name,
        folders: session.folders,
        sourcePages: <PageRef>[
          for (final page in session.pages) page.toPageRef(),
        ],
        folderId: session.folderId,
        candidateRequest: GeneratedPdfCandidateRequest(
          pages: <GeneratedPdfCandidatePage>[
            for (var index = 0; index < session.pages.length; index++)
              GeneratedPdfCandidatePage(
                stableId: session.pages[index].id.value,
                page: PdfPageSpec(
                  imagePath: preparedPaths[index],
                  rotation: PageRotation.none,
                ),
                quality: PdfQualityPercent(value: orderedQualities[index]),
              ),
          ],
          fingerprint: PdfCandidateFingerprint(
            sourceIdentity: <String>[
              session.sessionId,
              for (final page in session.pages)
                PageRenderPlan.of(page, scale: RenderScale.full).cacheKey,
            ].join(':'),
            configurationIdentity: qualityPlan.toJson().toString(),
            orderedPageQualities: orderedQualities,
            isProtected: password != null,
          ),
          password: password,
        ),
      );
    }

    final cubit = SavePdfCubit(
      pages: <PageRef>[for (final page in session.pages) page.toPageRef()],
      initialName: session.suggestedName,
      initialQuality: widget.initialQuality,
      calculate: CalculateSavePdfSize(repository, cache),
      preparePreview: PrepareSavePdfPreview(repository, cache),
      save: SaveGeneratedPdf(
        repository: repository,
        cache: cache,
        documents: widget.documents,
        rollbackDocument: widget.rollbackDocument,
        store: widget.store,
        secrets: widget.secrets,
        clock: widget.clock,
        ids: widget.ids,
        workingDirectory: widget.workingDirectory,
        completeSession: () async {
          await widget.discardSession(session.sessionId);
          widget.sessions.remove(widget.sessionHandle);
        },
      ),
      requestFactory: requestFactory,
    );
    setState(() {
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
    if (cubit != null) unawaited(cubit.close());
    final cache = _cache;
    final repository = _repository;
    if (cache != null && repository != null) {
      unawaited(cache.dispose(repository));
    }
    widget.sessions.remove(widget.sessionHandle);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final failure = _failure;
    if (failure != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Save PDF')),
        body: AppErrorView(failure: failure, onRetry: _load),
      );
    }
    final cubit = _cubit;
    if (cubit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Save PDF')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return SavePdfScreen(
      cubit: cubit,
      onOpenPreview: (handle) {
        final route = PdfTemporaryPreviewRoute(candidateHandle: handle);
        context.push<void>(route.location, extra: route);
      },
      onSaved: context.pop,
    );
  }
}
