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
class CropScreen extends StatefulWidget {
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
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  Size? _imageSize;

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
            onPressed: widget.onCancelled,
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
              child: _CropCanvas(
                state: state,
                onImageSize: (size) {
                  if (_imageSize == size) return;
                  // Set outside the build it was reported from.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _imageSize = size);
                  });
                },
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FlipControls(enabled: !state.isWorking, quad: state.quad),
                const SizedBox(height: 12),
                FilledButton(
                  key: ScanKeys.cropConfirmButton,
                  onPressed: state.isWorking
                      ? null
                      : () async {
                          final page = await context.read<CropCubit>().confirm(
                            destinationPath: widget.destinationPath,
                          );
                          if (page != null) widget.onCropped(page);
                        },
                  child: const Text('Apply crop'),
                ),
              ],
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
  const _CropCanvas({required this.state, required this.onImageSize});

  final CropState state;

  /// Reports the page's pixel size once it is known.
  ///
  /// The rotation dial needs it: turning a quad in normalised space would
  /// stretch it, because the two axes are not the same number of pixels.
  final ValueChanged<Size> onImageSize;

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
        final size = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
        setState(() => _imageSize = size);
        widget.onImageSize(size);
      },
      // An unreadable page still gets a usable overlay: the fallback below
      // treats the whole canvas as the image, which is the old behaviour.
      onError: (_, _) {},
    );

    _stream = provider.resolve(const ImageConfiguration())
      ..addListener(listener);
    _listener = listener;
  }

  /// The rectangle the page occupies, laid out inside a margin for the handles.
  ///
  /// The margin is taken out of the canvas *before* the page is fitted, not
  /// added around the canvas. Padding the canvas instead leaves the page filling
  /// it edge to edge on one axis, so a handle centred on a corner still hangs
  /// half outside the Stack — clipped, invisible and unhittable — and the rotate
  /// handle, which sits further out again, disappears entirely.
  ///
  /// Falls back to the same inset rectangle until the page's size is known, so
  /// the overlay is never missing, only briefly less accurate.
  Rect _imageRect(Size canvas) {
    // A whole fingertip either side of a corner, and enough below the page for
    // the rotate handle to hang clear of it.
    const side = AppTheme.minimumTouchTarget / 2 + 8;
    const bottom = _rotateHandleReach + AppTheme.minimumTouchTarget / 2;

    final available = Rect.fromLTWH(
      side,
      side,
      math.max(1, canvas.width - side * 2),
      math.max(1, canvas.height - side - bottom),
    );

    final size = _imageSize;
    if (size == null || size.isEmpty) return available;

    final fitted = applyBoxFit(BoxFit.contain, size, available.size);
    return Alignment.center.inscribe(fitted.destination, available);
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
            // Drawn into exactly the rectangle the overlay is mapped through,
            // rather than filling the canvas: any difference between the two
            // puts the outline somewhere other than the page it describes.
            // BoxFit.fill is safe here because imageRect already carries the
            // page's aspect ratio.
            if (provider != null)
              Positioned.fromRect(
                rect: imageRect,
                child: Image(
                  image: provider,
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(color: Colors.black12),
                ),
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
            _RotateHandle(
              quad: widget.state.quad,
              imageRect: imageRect,
              enabled: !widget.state.isWorking,
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

/// How far the rotate handle hangs below the quad's bottom edge, in pixels.
const _rotateHandleReach = 56.0;

/// Where the rotate handle sits for [quad], in canvas coordinates.
///
/// Hung off the bottom edge along its outward normal, so it follows the shape
/// as it is dragged and turned instead of floating at a fixed point.
Offset rotateHandlePosition(PageQuad quad, Rect imageRect) {
  final left = _toCanvas(quad.bottomLeft, imageRect);
  final right = _toCanvas(quad.bottomRight, imageRect);
  final midpoint = Offset.lerp(left, right, 0.5)!;

  final edge = right - left;
  final length = edge.distance;
  if (length == 0) return midpoint + const Offset(0, _rotateHandleReach);

  // Normal pointing away from the quad's centre.
  final normal = Offset(-edge.dy, edge.dx) / length;
  final centre =
      [
        _toCanvas(quad.topLeft, imageRect),
        _toCanvas(quad.topRight, imageRect),
        right,
        left,
      ].reduce((a, b) => a + b) /
      4;

  final outward = midpoint - centre;
  final sign = (normal.dx * outward.dx + normal.dy * outward.dy) < 0
      ? -1.0
      : 1.0;

  return midpoint + normal * sign * _rotateHandleReach;
}

/// The free-rotation handle, dragged in a circle to turn the selection.
///
/// Turning the selection turns the result: the correction maps these corners
/// onto an upright rectangle, so a quad dragged square onto a tilted page comes
/// out straight. That is also why there is no separate "rotate the image" step
/// — there is only one resampling pass, and no blank corners to fill.
class _RotateHandle extends StatefulWidget {
  const _RotateHandle({
    required this.quad,
    required this.imageRect,
    required this.enabled,
  });

  final PageQuad quad;
  final Rect imageRect;
  final bool enabled;

  @override
  State<_RotateHandle> createState() => _RotateHandleState();
}

class _RotateHandleState extends State<_RotateHandle> {
  /// The quad as it was when this drag began.
  ///
  /// Every update is measured against it, so the page follows the finger
  /// instead of compounding its own rotation and spinning away.
  PageQuad? _base;
  Offset _pointer = Offset.zero;
  double _startAngle = 0;

  Offset get _centre {
    final corners = [
      for (final corner in widget.quad.corners)
        _toCanvas(corner, widget.imageRect),
    ];
    return corners.reduce((a, b) => a + b) / 4;
  }

  Size? get _imageSize {
    final rect = widget.imageRect;
    return rect.isEmpty ? null : rect.size;
  }

  @override
  Widget build(BuildContext context) {
    final position = rotateHandlePosition(widget.quad, widget.imageRect);

    return Positioned(
      left: position.dx - AppTheme.minimumTouchTarget / 2,
      top: position.dy - AppTheme.minimumTouchTarget / 2,
      child: Semantics(
        label: 'Rotate page',
        child: ExcludeSemantics(
          child: GestureDetector(
            key: ScanKeys.cropRotateHandle,
            onPanStart: widget.enabled ? (_) => _start(position) : null,
            onPanUpdate: widget.enabled ? _update : null,
            onPanEnd: widget.enabled ? (_) => _end() : null,
            onPanCancel: widget.enabled ? _end : null,
            child: SizedBox(
              width: AppTheme.minimumTouchTarget,
              height: AppTheme.minimumTouchTarget,
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.rotate_right,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _start(Offset position) {
    _base = widget.quad;
    _pointer = position;
    _startAngle = _angleTo(position);
  }

  void _update(DragUpdateDetails details) {
    final base = _base;
    final size = _imageSize;
    if (base == null || size == null) return;

    _pointer += details.delta;

    // Measured in canvas space but applied in image space, so the turn matches
    // the finger even though the page is letterboxed inside the canvas.
    final degrees = (_angleTo(_pointer) - _startAngle) * 180 / math.pi;

    context.read<CropCubit>().adjust(
      rotateQuad(base, degrees, widget.imageRect.size),
    );
  }

  void _end() => _base = null;

  double _angleTo(Offset point) {
    final delta = point - _centre;
    return math.atan2(delta.dy, delta.dx);
  }
}

/// Mirror controls.
///
/// Separate from the rotate handle because turning past half a turn is a
/// mirror, not a rotation — a page dragged all the way round comes back to
/// where it started, so "flipped" is a state the handle can never reach.
class _FlipControls extends StatelessWidget {
  const _FlipControls({required this.enabled, required this.quad});

  final bool enabled;
  final PageQuad quad;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CropCubit>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          key: ScanKeys.cropFlipHorizontalButton,
          onPressed: enabled
              ? () => cubit.adjust(flipQuadHorizontally(quad))
              : null,
          icon: const Icon(Icons.flip),
          label: const Text('Flip H'),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          key: ScanKeys.cropFlipVerticalButton,
          onPressed: enabled
              ? () => cubit.adjust(flipQuadVertically(quad))
              : null,
          icon: const RotatedBox(quarterTurns: 1, child: Icon(Icons.flip)),
          label: const Text('Flip V'),
        ),
      ],
    );
  }
}

/// Returns [quad] mirrored left-to-right.
///
/// Swapping the corners rather than the pixels: the correction maps these four
/// points onto the output rectangle, so exchanging the left pair with the right
/// pair produces a mirrored page for free.
PageQuad flipQuadHorizontally(PageQuad quad) => PageQuad(
  topLeft: quad.topRight,
  topRight: quad.topLeft,
  bottomRight: quad.bottomLeft,
  bottomLeft: quad.bottomRight,
);

/// Returns [quad] mirrored top-to-bottom.
PageQuad flipQuadVertically(PageQuad quad) => PageQuad(
  topLeft: quad.bottomLeft,
  topRight: quad.bottomRight,
  bottomRight: quad.topRight,
  bottomLeft: quad.topLeft,
);

/// Returns [quad] turned [degrees] clockwise about its own centre.
///
/// Rotating the selection rather than the image is what makes free-form
/// straightening cheap: the perspective transform already maps these four
/// corners onto a rectangle, so a quad turned to sit square on a tilted page
/// produces an upright result. The alternative — rotating the pixels — would
/// mean a second resampling pass and corners with nothing in them.
///
/// The rotation is done in pixel space. Normalised axes are both 0..1 while the
/// page is not square, so turning the points there would stretch the quad by
/// the aspect ratio.
PageQuad rotateQuad(PageQuad quad, double degrees, Size imageSize) {
  if (degrees == 0 || imageSize.isEmpty) return quad;

  final radians = degrees * math.pi / 180;
  final cos = math.cos(radians);
  final sin = math.sin(radians);

  final points = [
    for (final corner in quad.corners)
      Offset(corner.x * imageSize.width, corner.y * imageSize.height),
  ];

  final centre = points.reduce((a, b) => a + b) / points.length.toDouble();

  NormalisedPoint turned(Offset point) {
    final dx = point.dx - centre.dx;
    final dy = point.dy - centre.dy;

    return NormalisedPoint(
      x: (centre.dx + dx * cos - dy * sin) / imageSize.width,
      y: (centre.dy + dx * sin + dy * cos) / imageSize.height,
    );
  }

  return shrinkQuadToFit(
    PageQuad(
      topLeft: turned(points[0]),
      topRight: turned(points[1]),
      bottomRight: turned(points[2]),
      bottomLeft: turned(points[3]),
    ),
  );
}

/// Returns [quad] scaled about its centre until it lies inside the page.
///
/// Scaled rather than clamped. Clamping each corner independently would drag
/// the overhanging ones along the edges and leave a different shape than the
/// one being turned — the selection would visibly deform as it rotated.
/// Shrinking keeps it the same shape, just smaller, so the crop is never larger
/// than the image it comes from.
PageQuad shrinkQuadToFit(PageQuad quad) {
  final corners = quad.corners;
  final centre = Offset(
    corners.map((c) => c.x).reduce((a, b) => a + b) / corners.length,
    corners.map((c) => c.y).reduce((a, b) => a + b) / corners.length,
  );

  var scale = 1.0;

  /// The largest factor keeping [value] within 0..1 when scaled about [origin].
  void limit(double value, double origin) {
    final delta = value - origin;
    if (delta > 0) {
      scale = math.min(scale, (1 - origin) / delta);
    } else if (delta < 0) {
      scale = math.min(scale, origin / -delta);
    }
  }

  for (final corner in corners) {
    limit(corner.x, centre.dx);
    limit(corner.y, centre.dy);
  }

  // Already inside, or the centre itself is out of bounds and there is no
  // scaling that helps — leave it be rather than collapse it to a point.
  if (scale >= 1 || scale <= 0) return quad;

  NormalisedPoint scaled(NormalisedPoint point) => NormalisedPoint(
    x: (centre.dx + (point.x - centre.dx) * scale).clamp(0.0, 1.0),
    y: (centre.dy + (point.y - centre.dy) * scale).clamp(0.0, 1.0),
  );

  return PageQuad(
    topLeft: scaled(quad.topLeft),
    topRight: scaled(quad.topRight),
    bottomRight: scaled(quad.bottomRight),
    bottomLeft: scaled(quad.bottomLeft),
  );
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

    // The stem connecting the rotate handle to the edge it hangs from, so the
    // handle reads as part of the shape rather than as something floating
    // beside it.
    canvas.drawLine(
      Offset.lerp(points[3], points[2], 0.5)!,
      rotateHandlePosition(quad, imageRect),
      Paint()
        ..strokeWidth = 2
        ..color = colour,
    );
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
