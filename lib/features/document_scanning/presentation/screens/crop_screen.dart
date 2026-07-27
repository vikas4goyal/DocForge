/// The crop screen and its draggable edge overlay.
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/theme/app_theme.dart';
import 'package:doc_forge/features/document_scanning/domain/scan_session.dart';
import 'package:doc_forge/features/document_scanning/presentation/cubit/scan_cubits.dart';
import 'package:doc_forge/features/document_scanning/presentation/cubit/scan_states.dart';
import 'package:doc_forge/features/document_scanning/presentation/scan_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Lets the user adjust a page's edges before correction is applied.
class CropScreen extends StatelessWidget {
  /// Creates the crop screen.
  const CropScreen({
    required this.destinationPath,
    required this.onCropped,
    required this.onCancelled,
    super.key,
  });

  /// Where the corrected page is written.
  final String destinationPath;

  /// Called with the corrected page once the crop is applied.
  final void Function(CapturedPage page) onCropped;

  /// Called when the user leaves without applying a crop.
  final VoidCallback onCancelled;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CropCubit, CropState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure && current.failure != null,
      listener: (context, state) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.message ?? ''))),
      builder: (context, state) => Scaffold(
        key: ScanKeys.cropScreen,
        appBar: AppBar(
          title: const Text('Adjust edges'),
          leading: IconButton(
            key: const Key('scan_crop_cancel_button'),
            tooltip: 'Cancel cropping',
            onPressed: onCancelled,
            icon: const Icon(Icons.close),
          ),
          actions: [
            TextButton(
              key: ScanKeys.cropResetButton,
              onPressed: state.isWorking
                  ? null
                  : context.read<CropCubit>().reset,
              child: const Text('Reset'),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Inset so the page never reaches the screen edge. A corner sitting
            // against it is unusable: half the touch target is off-screen, and
            // the drag that is left starts in the system's back-swipe and
            // control-centre gutters, so the gesture leaves the app instead of
            // moving the handle. The margin is a little over one touch target,
            // which is what it takes to get a whole fingertip beside a corner.
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 20,
                ),
                child: _CropCanvas(state: state),
              ),
            ),
            if (state.isWorking)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black54,
                  child: Center(child: CircularProgressIndicator.adaptive()),
                ),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              key: ScanKeys.cropConfirmButton,
              onPressed: state.isWorking
                  ? null
                  : () async {
                      final page = await context.read<CropCubit>().confirm(
                        destinationPath: destinationPath,
                      );
                      if (page != null) onCropped(page);
                    },
              child: const Text('Apply crop'),
            ),
          ),
        ),
      ),
    );
  }
}

/// The page image with the draggable quadrilateral over it.
///
/// Stateful because the overlay has to be positioned against the *image*, not
/// the canvas. `BoxFit.contain` letterboxes the page whenever its aspect ratio
/// differs from the screen's, so a quad laid out in canvas coordinates sits
/// somewhere other than the page it is supposed to describe — the corner the
/// user drags onto a document edge lands somewhere else entirely. Mapping
/// through the displayed rectangle needs the image's intrinsic size, which is
/// only known once it has been decoded.
class _CropCanvas extends StatefulWidget {
  const _CropCanvas({required this.state});

  final CropState state;

  @override
  State<_CropCanvas> createState() => _CropCanvasState();
}

class _CropCanvasState extends State<_CropCanvas> {
  ImageProvider<Object>? _provider;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  Size? _imageSize;

  /// Where the finger is while a handle is being dragged, in canvas space.
  ///
  /// Drives the magnifier: a fingertip covers the very corner being placed, so
  /// without one the last few pixels are positioned blind.
  Offset? _dragPoint;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(_CropCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.page.imagePath != widget.state.page.imagePath) {
      _resolveImage();
    }
  }

  @override
  void dispose() {
    _detachListener();
    super.dispose();
  }

  void _detachListener() {
    final stream = _stream;
    final listener = _listener;
    if (stream != null && listener != null) stream.removeListener(listener);
    _stream = null;
    _listener = null;
  }

  /// Starts decoding the page so its intrinsic size is known.
  ///
  /// The same provider is handed to the `Image` below, so this resolve shares
  /// the decode rather than paying for a second one.
  void _resolveImage() {
    _detachListener();
    _imageSize = null;

    final provider = FileImage(File(widget.state.page.imagePath));
    _provider = provider;

    final listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        setState(
          () => _imageSize = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          ),
        );
      },
      // An unreadable page still gets a usable overlay: the fallback below
      // treats the whole canvas as the image, which is the old behaviour.
      onError: (_, _) {},
    );

    _stream = provider.resolve(const ImageConfiguration())
      ..addListener(listener);
    _listener = listener;
  }

  /// The rectangle the page actually occupies inside [canvas].
  ///
  /// Falls back to the whole canvas until the size is known, so the overlay is
  /// never missing — only briefly less accurate.
  Rect _imageRect(Size canvas) {
    final size = _imageSize;
    if (size == null || size.isEmpty) return Offset.zero & canvas;

    final fitted = applyBoxFit(BoxFit.contain, size, canvas);
    return Alignment.center.inscribe(fitted.destination, Offset.zero & canvas);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvas = Size(constraints.maxWidth, constraints.maxHeight);
        final imageRect = _imageRect(canvas);
        final provider = _provider;
        final scheme = Theme.of(context).colorScheme;

        return Stack(
          fit: StackFit.expand,
          children: [
            if (provider != null)
              Image(
                image: provider,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const ColoredBox(color: Colors.black12),
              ),
            CustomPaint(
              key: ScanKeys.edgeOverlay,
              painter: _QuadPainter(
                quad: widget.state.quad,
                imageRect: imageRect,
                colour: scheme.primary,
              ),
            ),
            for (var edge = 0; edge < 4; edge++)
              _EdgeHandle(
                edge: edge,
                quad: widget.state.quad,
                imageRect: imageRect,
                enabled: !widget.state.isWorking,
                onDragPoint: _setDragPoint,
              ),
            for (var corner = 0; corner < 4; corner++)
              _CornerHandle(
                corner: corner,
                quad: widget.state.quad,
                imageRect: imageRect,
                enabled: !widget.state.isWorking,
                onDragPoint: _setDragPoint,
              ),
            if (_dragPoint != null)
              _CornerMagnifier(focus: _dragPoint!, canvas: canvas),
          ],
        );
      },
    );
  }

  void _setDragPoint(Offset? point) {
    if (_dragPoint == point) return;
    setState(() => _dragPoint = point);
  }
}

/// Magnifies the area under the finger while a handle is being dragged.
///
/// Offset above the touch point rather than centred on it, because the thing
/// worth seeing is precisely what the fingertip is covering.
class _CornerMagnifier extends StatelessWidget {
  const _CornerMagnifier({required this.focus, required this.canvas});

  final Offset focus;
  final Size canvas;

  static const _size = Size(112, 112);
  static const _lift = 96.0;

  @override
  Widget build(BuildContext context) {
    // Flips below the finger near the top of the screen, where there is no room
    // above it, so the loupe never leaves the canvas.
    final above = focus.dy - _lift - _size.height / 2 >= 0;
    final centre = Offset(
      focus.dx.clamp(_size.width / 2, canvas.width - _size.width / 2),
      above ? focus.dy - _lift : focus.dy + _lift,
    );

    return Positioned(
      left: centre.dx - _size.width / 2,
      top: (centre.dy - _size.height / 2).clamp(
        0.0,
        canvas.height - _size.height,
      ),
      child: IgnorePointer(
        child: RawMagnifier(
          size: _size,
          magnificationScale: 2,
          focalPointOffset: focus - centre,
          decoration: MagnifierDecoration(
            shape: CircleBorder(
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Maps a normalised page point into canvas coordinates.
///
/// Normalised coordinates describe the *image*, so they are mapped through the
/// rectangle the image is actually drawn in rather than the canvas.
Offset _toCanvas(NormalisedPoint point, Rect imageRect) => Offset(
  imageRect.left + point.x * imageRect.width,
  imageRect.top + point.y * imageRect.height,
);

/// Maps a canvas point back to normalised page coordinates.
///
/// Clamped to the image: a corner outside it would describe a crop of pixels
/// that do not exist, which the transform would then have to guess at.
NormalisedPoint _toNormalised(Offset point, Rect imageRect) => NormalisedPoint(
  x: imageRect.width == 0
      ? 0
      : ((point.dx - imageRect.left) / imageRect.width).clamp(0.0, 1.0),
  y: imageRect.height == 0
      ? 0
      : ((point.dy - imageRect.top) / imageRect.height).clamp(0.0, 1.0),
);

/// Draws the crop quadrilateral.
class _QuadPainter extends CustomPainter {
  const _QuadPainter({
    required this.quad,
    required this.imageRect,
    required this.colour,
  });

  final PageQuad quad;
  final Rect imageRect;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      for (final corner in quad.corners) _toCanvas(corner, imageRect),
    ];

    final path = Path()..addPolygon(points, true);

    // The area outside the crop is dimmed rather than the inside being tinted,
    // so the user judges the page itself at its true colour.
    canvas
      ..drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(Offset.zero & size),
          path,
        ),
        Paint()..color = Colors.black54,
      )
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = colour,
      );

    _paintThirds(canvas, points);
  }

  /// Draws thirds guides inside the quad.
  ///
  /// Interpolated along the edges rather than drawn on a rectangle, so they
  /// follow the perspective of the page and show whether the quad is really
  /// tracking the document.
  void _paintThirds(Canvas canvas, List<Offset> points) {
    final guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = colour.withValues(alpha: 0.35);

    Offset lerp(Offset a, Offset b, double t) => Offset.lerp(a, b, t)!;

    for (final t in const [1 / 3, 2 / 3]) {
      canvas
        ..drawLine(
          lerp(points[0], points[1], t),
          lerp(points[3], points[2], t),
          guide,
        )
        ..drawLine(
          lerp(points[0], points[3], t),
          lerp(points[1], points[2], t),
          guide,
        );
    }
  }

  @override
  bool shouldRepaint(_QuadPainter oldDelegate) =>
      oldDelegate.quad != quad ||
      oldDelegate.colour != colour ||
      oldDelegate.imageRect != imageRect;
}

/// One draggable corner of the crop.
class _CornerHandle extends StatelessWidget {
  const _CornerHandle({
    required this.corner,
    required this.quad,
    required this.imageRect,
    required this.enabled,
    required this.onDragPoint,
  });

  final int corner;
  final PageQuad quad;
  final Rect imageRect;
  final bool enabled;
  final ValueChanged<Offset?> onDragPoint;

  /// Visual radius of a handle.
  static const _radius = 12.0;

  @override
  Widget build(BuildContext context) {
    final centre = _toCanvas(quad.corners[corner], imageRect);

    return Positioned(
      // The hit area is 48dp square and centred on the corner, while the drawn
      // handle is much smaller: a 24dp target under a fingertip is unusable,
      // and the accessibility baseline requires 48dp regardless.
      left: centre.dx - AppTheme.minimumTouchTarget / 2,
      top: centre.dy - AppTheme.minimumTouchTarget / 2,
      child: Semantics(
        label: _labelFor(corner),
        child: ExcludeSemantics(
          child: GestureDetector(
            key: ScanKeys.cropHandle(corner),
            onPanStart: enabled ? (_) => onDragPoint(centre) : null,
            onPanUpdate: enabled
                ? (details) => _drag(context, centre, details)
                : null,
            onPanEnd: enabled ? (_) => onDragPoint(null) : null,
            onPanCancel: enabled ? () => onDragPoint(null) : null,
            child: SizedBox(
              width: AppTheme.minimumTouchTarget,
              height: AppTheme.minimumTouchTarget,
              child: Center(
                child: Container(
                  width: _radius * 2,
                  height: _radius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Moves this corner to follow the drag.
  void _drag(BuildContext context, Offset centre, DragUpdateDetails details) {
    final moved = centre + details.delta;
    onDragPoint(moved);
    context.read<CropCubit>().adjust(
      _replaceCorner(quad, corner, _toNormalised(moved, imageRect)),
    );
  }

  static String _labelFor(int corner) => switch (corner) {
    0 => 'Top left crop handle',
    1 => 'Top right crop handle',
    2 => 'Bottom right crop handle',
    _ => 'Bottom left crop handle',
  };
}

/// One draggable edge of the crop.
///
/// Moves both of the edge's corners together, which is how a page is squared up
/// against a margin — chasing the two corners separately to straighten one side
/// is the fiddliest part of adjusting a crop by hand.
class _EdgeHandle extends StatelessWidget {
  const _EdgeHandle({
    required this.edge,
    required this.quad,
    required this.imageRect,
    required this.enabled,
    required this.onDragPoint,
  });

  final int edge;
  final PageQuad quad;
  final Rect imageRect;
  final bool enabled;
  final ValueChanged<Offset?> onDragPoint;

  /// The two corner indices this edge joins, clockwise from the top edge.
  (int, int) get _corners => switch (edge) {
    0 => (0, 1),
    1 => (1, 2),
    2 => (2, 3),
    _ => (3, 0),
  };

  @override
  Widget build(BuildContext context) {
    final (first, second) = _corners;
    final centre = Offset.lerp(
      _toCanvas(quad.corners[first], imageRect),
      _toCanvas(quad.corners[second], imageRect),
      0.5,
    )!;

    return Positioned(
      left: centre.dx - AppTheme.minimumTouchTarget / 2,
      top: centre.dy - AppTheme.minimumTouchTarget / 2,
      child: Semantics(
        label: _labelFor(edge),
        child: ExcludeSemantics(
          child: GestureDetector(
            key: ScanKeys.cropEdgeHandle(edge),
            onPanStart: enabled ? (_) => onDragPoint(centre) : null,
            onPanUpdate: enabled
                ? (details) => _drag(context, centre, details)
                : null,
            onPanEnd: enabled ? (_) => onDragPoint(null) : null,
            onPanCancel: enabled ? () => onDragPoint(null) : null,
            child: SizedBox(
              width: AppTheme.minimumTouchTarget,
              height: AppTheme.minimumTouchTarget,
              child: Center(
                // A bar rather than a disc, so it reads as "this whole side
                // moves" instead of "this point moves".
                child: Transform.rotate(
                  angle: edge.isEven ? 0 : math.pi / 2,
                  child: Container(
                    width: 28,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Theme.of(context).colorScheme.primary,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Moves both corners of this edge by the drag delta.
  void _drag(BuildContext context, Offset centre, DragUpdateDetails details) {
    final (first, second) = _corners;
    onDragPoint(centre + details.delta);

    Offset movedCorner(int index) =>
        _toCanvas(quad.corners[index], imageRect) + details.delta;

    var moved = _replaceCorner(
      quad,
      first,
      _toNormalised(movedCorner(first), imageRect),
    );
    moved = _replaceCorner(
      moved,
      second,
      _toNormalised(movedCorner(second), imageRect),
    );

    context.read<CropCubit>().adjust(moved);
  }

  static String _labelFor(int edge) => switch (edge) {
    0 => 'Top crop edge',
    1 => 'Right crop edge',
    2 => 'Bottom crop edge',
    _ => 'Left crop edge',
  };
}

/// Returns [quad] with corner [index] replaced by [point].
PageQuad _replaceCorner(PageQuad quad, int index, NormalisedPoint point) =>
    switch (index) {
      0 => quad.copyWith(topLeft: point),
      1 => quad.copyWith(topRight: point),
      2 => quad.copyWith(bottomRight: point),
      _ => quad.copyWith(bottomLeft: point),
    };
