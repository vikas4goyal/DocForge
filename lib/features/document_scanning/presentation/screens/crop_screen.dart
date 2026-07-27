/// The crop screen: a rotatable page under a draggable selection.
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

/// How far below the page the rotate handle sits, in logical pixels.
const _rotateHandleReach = 56.0;

/// Clear space kept either side of the page for the corner handles.
const _handleMargin = AppTheme.minimumTouchTarget / 2 + 8;

/// Places a page inside the canvas at a rotation, and converts between the two.
///
/// The page turns under a selection that stays where the user put it, which is
/// what makes straightening feel like straightening rather than like skewing a
/// box. The selection itself is still stored against the *unrotated* image, and
/// nothing downstream knows this class exists: turning the page on screen by an
/// angle is the same as turning the selection by minus that angle, so the
/// perspective correction goes on receiving the document's outline in the
/// capture's own coordinates.
@immutable
class PageTransform {
  /// Creates a transform placing [imageSize] at [centre].
  const PageTransform({
    required this.imageSize,
    required this.centre,
    required this.scale,
    required this.radians,
  });

  /// Fits [imageSize] inside [available], leaving it whole at any rotation.
  ///
  /// The page is measured by the box its *rotated* self occupies, so a page
  /// turned to 45° shrinks to stay inside rather than having its corners cut
  /// off. It is never scaled up: a small capture is shown at its own size
  /// instead of being enlarged into blur.
  factory PageTransform.fit({
    required Size imageSize,
    required Rect available,
    required double degrees,
  }) {
    final radians = degrees * math.pi / 180;
    final cos = math.cos(radians).abs();
    final sin = math.sin(radians).abs();

    final rotatedWidth = imageSize.width * cos + imageSize.height * sin;
    final rotatedHeight = imageSize.width * sin + imageSize.height * cos;

    final scale = math.min(
      1.0,
      math.min(
        available.width / math.max(rotatedWidth, 1),
        available.height / math.max(rotatedHeight, 1),
      ),
    );

    return PageTransform(
      imageSize: imageSize,
      centre: available.center,
      scale: scale,
      radians: radians,
    );
  }

  /// The page's pixel dimensions.
  final Size imageSize;

  /// Where the page's centre sits on the canvas.
  final Offset centre;

  /// Logical pixels per image pixel.
  final double scale;

  /// Clockwise rotation applied to the page.
  final double radians;

  /// The page's on-screen size, before rotation.
  Size get displaySize => imageSize * scale;

  /// The box the page occupies once turned.
  ///
  /// What the rotate handle is positioned against, so it stays just clear of
  /// the page at every angle rather than drifting away from it or riding over
  /// a corner as the page swings.
  Size get rotatedSize {
    final cos = math.cos(radians).abs();
    final sin = math.sin(radians).abs();
    final size = displaySize;

    return Size(
      size.width * cos + size.height * sin,
      size.width * sin + size.height * cos,
    );
  }

  /// Converts a point on the page into canvas coordinates.
  Offset toScreen(NormalisedPoint point) {
    final dx = (point.x - 0.5) * imageSize.width * scale;
    final dy = (point.y - 0.5) * imageSize.height * scale;
    final cos = math.cos(radians);
    final sin = math.sin(radians);

    return centre + Offset(dx * cos - dy * sin, dx * sin + dy * cos);
  }

  /// Converts a canvas point back onto the page.
  ///
  /// [clamp] keeps the result on the page, which is what a corner being dragged
  /// wants: a corner pulled past the edge would describe pixels that do not
  /// exist. Turning the page wants the opposite — the selection belongs to the
  /// canvas and must keep its shape, so a corner the page has swung out from
  /// under is left where it is rather than dragged inward, which would deform
  /// the box as it turned. The correction samples the nearest edge for anything
  /// outside, so the overhang is a smeared border rather than a failure.
  NormalisedPoint toPage(Offset point, {bool clamp = true}) {
    final delta = point - centre;
    final cos = math.cos(-radians);
    final sin = math.sin(-radians);

    final dx = delta.dx * cos - delta.dy * sin;
    final dy = delta.dx * sin + delta.dy * cos;

    final x = dx / (imageSize.width * scale) + 0.5;
    final y = dy / (imageSize.height * scale) + 0.5;

    return NormalisedPoint(
      x: clamp ? x.clamp(0.0, 1.0) : x,
      y: clamp ? y.clamp(0.0, 1.0) : y,
    );
  }
}

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
  /// How far the page has been turned, in degrees.
  ///
  /// A view concern only. The selection is stored against the unrotated
  /// capture, so what leaves this screen is the document's outline in the
  /// capture's own coordinates — which is what the correction expects.
  double _rotation = 0;

  /// The area the page is laid out in, reported by the canvas.
  Rect? _available;

  /// The page's pixel size, once decoded.
  Size? _imageSize;

  /// Mirrors the page, squaring it first.
  ///
  /// A flip is applied to an upright page. Mirroring one that is also turned
  /// leaves an orientation that is hard to predict and harder to undo — the
  /// rotation reverses along with the page — so the page is returned to square
  /// and then mirrored, which is one obvious result rather than two combined.
  void _flip(BuildContext context, {required bool horizontal}) {
    final cubit = context.read<CropCubit>();
    _rotate(context, 0);

    final quad = cubit.state.quad;
    cubit.adjust(
      horizontal ? flipQuadHorizontally(quad) : flipQuadVertically(quad),
    );
  }

  /// Turns the page while leaving the selection where it is on screen.
  ///
  /// The selection belongs to the canvas, not to the page: turning the page
  /// under a frame that stays put is what makes straightening feel like
  /// straightening. Because the selection is *stored* against the page, holding
  /// it still on screen means rewriting it — its screen corners are read
  /// through the old placement and written back through the new one, which also
  /// absorbs the rescale that comes with turning.
  void _rotate(BuildContext context, double degrees) {
    final available = _available;
    final imageSize = _imageSize;

    if (available == null || imageSize == null) {
      setState(() => _rotation = degrees);
      return;
    }

    final before = PageTransform.fit(
      imageSize: imageSize,
      available: available,
      degrees: _rotation,
    );
    final after = PageTransform.fit(
      imageSize: imageSize,
      available: available,
      degrees: degrees,
    );

    final quad = context.read<CropCubit>().state.quad;
    final held = [for (final corner in quad.corners) before.toScreen(corner)];

    setState(() => _rotation = degrees);
    context.read<CropCubit>().adjust(
      PageQuad(
        topLeft: after.toPage(held[0], clamp: false),
        topRight: after.toPage(held[1], clamp: false),
        bottomRight: after.toPage(held[2], clamp: false),
        bottomLeft: after.toPage(held[3], clamp: false),
      ),
    );
  }

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
            IconButton(
              key: ScanKeys.cropFlipHorizontalButton,
              tooltip: 'Flip horizontally',
              onPressed: state.isWorking
                  ? null
                  : () => _flip(context, horizontal: true),
              icon: const Icon(Icons.flip),
            ),
            IconButton(
              key: ScanKeys.cropFlipVerticalButton,
              tooltip: 'Flip vertically',
              onPressed: state.isWorking
                  ? null
                  : () => _flip(context, horizontal: false),
              icon: const RotatedBox(quarterTurns: 1, child: Icon(Icons.flip)),
            ),
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
            Positioned.fill(
              child: _CropCanvas(
                state: state,
                rotation: _rotation,
                onLayout: (available, imageSize) {
                  if (_available == available && _imageSize == imageSize) return;
                  // Reported from a build, so applied after it.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      _available = available;
                      _imageSize = imageSize;
                    });
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
                _RotationSlider(
                  degrees: _rotation,
                  enabled: !state.isWorking,
                  onChanged: (value) => _rotate(context, value),
                ),
                const SizedBox(height: 8),
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

/// Free-form rotation for the page beneath the selection.
///
/// A slider rather than a handle dragged in a circle: straightening a scan is
/// usually a correction of a few degrees, and a degree is a couple of pixels of
/// travel on a handle but a comfortable movement on a track. The reading is
/// shown because "about right" is not the same as square.
///
/// Runs a quarter turn either way from zero. A page can be off in either
/// direction, so both are reachable — and holding the range to ±90 rather than
/// ±180 puts twice the travel behind every degree, which is what makes a
/// one-degree correction possible with a fingertip. The orientations that fall
/// outside it are reached by the flips instead: a half turn is both of them.
class _RotationSlider extends StatelessWidget {
  const _RotationSlider({
    required this.degrees,
    required this.enabled,
    required this.onChanged,
  });

  final double degrees;
  final bool enabled;
  final ValueChanged<double> onChanged;

  static const _range = 90.0;

  @override
  Widget build(BuildContext context) {
    final reading = degrees.toStringAsFixed(1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Above the track rather than beside it, so the slider keeps the full
        // width. A tenth of a degree is visible in the reading even though it is
        // far finer than a fingertip can place, because the number is what turns
        // "about right" into square.
        Text(
          '$reading°',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        Row(
          children: [
            IconButton(
              key: ScanKeys.cropRotationReset,
              tooltip: 'Straighten',
              onPressed: enabled && degrees != 0 ? () => onChanged(0) : null,
              icon: const Icon(Icons.settings_backup_restore),
            ),
            Expanded(
              child: Semantics(
                label: 'Rotate page',
                value: '$reading degrees',
                child: Slider(
                  key: ScanKeys.cropRotationSlider,
                  value: degrees.clamp(-_range, _range),
                  min: -_range,
                  max: _range,
                  // Continuous rather than notched: straightening lands wherever
                  // the page happens to be off by, which is rarely a round
                  // number.
                  label: '$reading°',
                  onChanged: enabled ? onChanged : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The page, its selection, and the handles that move both.
class _CropCanvas extends StatefulWidget {
  const _CropCanvas({
    required this.state,
    required this.rotation,
    required this.onLayout,
  });

  final CropState state;

  /// How far the page is turned. Owned by the screen, which also holds the
  /// slider that changes it.
  final double rotation;

  /// Reports the area the page was laid out in, and its pixel size.
  ///
  /// The screen needs both to keep the selection still while the page turns:
  /// it reads the selection's screen position through the old placement and
  /// writes it back through the new one.
  final void Function(Rect available, Size? imageSize) onLayout;

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
      // stands in a square page so the handles remain where they can be seen.
      onError: (_, _) {},
    );

    _stream = provider.resolve(const ImageConfiguration())
      ..addListener(listener);
    _listener = listener;
  }

  /// The area the page is laid out inside.
  ///
  /// The margin is taken out of the canvas *before* the page is fitted into what
  /// remains, never added around it. Padding the canvas instead leaves the page
  /// filling it edge to edge on one axis, so a handle centred on a corner hangs
  /// half outside — clipped, invisible and unhittable — and the rotate handle,
  /// which sits further out again, disappears entirely.
  Rect _available(Size canvas) => Rect.fromLTWH(
    _handleMargin,
    _handleMargin,
    math.max(1, canvas.width - _handleMargin * 2),
    math.max(
      1,
      canvas.height - _handleMargin - _rotateHandleReach - _handleMargin,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvas = Size(constraints.maxWidth, constraints.maxHeight);
        final available = _available(canvas);
        widget.onLayout(available, _imageSize);

        final transform = PageTransform.fit(
          // A square stand-in until the real size arrives, so the overlay is
          // never missing — only briefly less accurate.
          imageSize: _imageSize ?? const Size(1000, 1000),
          available: available,
          degrees: widget.rotation,
        );

        final provider = _provider;
        final enabled = !widget.state.isWorking;

        return Stack(
          fit: StackFit.expand,
          children: [
            if (provider != null) _page(provider, transform),
            CustomPaint(
              key: ScanKeys.edgeOverlay,
              painter: _SelectionPainter(
                quad: widget.state.quad,
                transform: transform,
                colour: Theme.of(context).colorScheme.primary,
              ),
            ),
            for (var edge = 0; edge < 4; edge++)
              _EdgeHandle(
                edge: edge,
                quad: widget.state.quad,
                transform: transform,
                enabled: enabled,
                onDragPoint: _setDragPoint,
              ),
            for (var corner = 0; corner < 4; corner++)
              _CornerHandle(
                corner: corner,
                quad: widget.state.quad,
                transform: transform,
                enabled: enabled,
                onDragPoint: _setDragPoint,
              ),
            if (_dragPoint != null)
              _CornerMagnifier(focus: _dragPoint!, canvas: canvas),
          ],
        );
      },
    );
  }

  /// The page itself, turned and scaled to sit inside the available area.
  Widget _page(ImageProvider<Object> provider, PageTransform transform) {
    final size = transform.displaySize;

    return Positioned(
      left: transform.centre.dx - size.width / 2,
      top: transform.centre.dy - size.height / 2,
      width: size.width,
      height: size.height,
      child: Transform.rotate(
        angle: transform.radians,
        child: Image(
          image: provider,
          // The box already carries the page's aspect ratio, so fill and
          // contain agree — and fill cannot letterbox the overlay out of step.
          fit: BoxFit.fill,
          errorBuilder: (context, error, stackTrace) =>
              const ColoredBox(color: Colors.black12),
        ),
      ),
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

/// Draws the selection over the page.
class _SelectionPainter extends CustomPainter {
  const _SelectionPainter({
    required this.quad,
    required this.transform,
    required this.colour,
  });

  final PageQuad quad;
  final PageTransform transform;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      for (final corner in quad.corners) transform.toScreen(corner),
    ];

    final path = Path()..addPolygon(points, true);

    // The area outside the selection is dimmed rather than the inside being
    // tinted, so the user judges the page itself at its true colour.
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

  /// Draws thirds guides inside the selection.
  ///
  /// Interpolated along the edges rather than drawn on a rectangle, so they
  /// follow the perspective of the page and show whether the selection is
  /// really tracking the document.
  void _paintThirds(Canvas canvas, List<Offset> points) {
    final guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = colour.withValues(alpha: 0.35);

    for (final t in const [1 / 3, 2 / 3]) {
      canvas
        ..drawLine(
          Offset.lerp(points[0], points[1], t)!,
          Offset.lerp(points[3], points[2], t)!,
          guide,
        )
        ..drawLine(
          Offset.lerp(points[0], points[3], t)!,
          Offset.lerp(points[1], points[2], t)!,
          guide,
        );
    }
  }

  @override
  bool shouldRepaint(_SelectionPainter oldDelegate) =>
      oldDelegate.quad != quad ||
      oldDelegate.colour != colour ||
      oldDelegate.transform != transform;
}

/// One draggable corner of the selection.
class _CornerHandle extends StatelessWidget {
  const _CornerHandle({
    required this.corner,
    required this.quad,
    required this.transform,
    required this.enabled,
    required this.onDragPoint,
  });

  final int corner;
  final PageQuad quad;
  final PageTransform transform;
  final bool enabled;
  final ValueChanged<Offset?> onDragPoint;

  static const _radius = 12.0;

  @override
  Widget build(BuildContext context) {
    final centre = transform.toScreen(quad.corners[corner]);

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

  void _drag(BuildContext context, Offset centre, DragUpdateDetails details) {
    final moved = centre + details.delta;
    onDragPoint(moved);
    context.read<CropCubit>().adjust(
      replaceCorner(quad, corner, transform.toPage(moved)),
    );
  }

  static String _labelFor(int corner) => switch (corner) {
    0 => 'Top left crop handle',
    1 => 'Top right crop handle',
    2 => 'Bottom right crop handle',
    _ => 'Bottom left crop handle',
  };
}

/// One draggable edge of the selection.
///
/// Moves both of the edge's corners together, which is how a page is squared up
/// against a margin — chasing the two corners separately to straighten one side
/// is the fiddliest part of adjusting a selection by hand.
class _EdgeHandle extends StatelessWidget {
  const _EdgeHandle({
    required this.edge,
    required this.quad,
    required this.transform,
    required this.enabled,
    required this.onDragPoint,
  });

  final int edge;
  final PageQuad quad;
  final PageTransform transform;
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
    final start = transform.toScreen(quad.corners[first]);
    final end = transform.toScreen(quad.corners[second]);
    final centre = Offset.lerp(start, end, 0.5)!;

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
                ? (details) => _drag(context, details)
                : null,
            onPanEnd: enabled ? (_) => onDragPoint(null) : null,
            onPanCancel: enabled ? () => onDragPoint(null) : null,
            child: SizedBox(
              width: AppTheme.minimumTouchTarget,
              height: AppTheme.minimumTouchTarget,
              child: Center(
                // Aligned with the edge it moves, so it reads as "this whole
                // side moves" rather than "this point moves".
                child: Transform.rotate(
                  angle: (end - start).direction,
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

  void _drag(BuildContext context, DragUpdateDetails details) {
    final (first, second) = _corners;

    Offset moved(int index) =>
        transform.toScreen(quad.corners[index]) + details.delta;

    onDragPoint(Offset.lerp(moved(first), moved(second), 0.5));

    var next = replaceCorner(quad, first, transform.toPage(moved(first)));
    next = replaceCorner(next, second, transform.toPage(moved(second)));

    context.read<CropCubit>().adjust(next);
  }

  static String _labelFor(int edge) => switch (edge) {
    0 => 'Top crop edge',
    1 => 'Right crop edge',
    2 => 'Bottom crop edge',
    _ => 'Left crop edge',
  };
}

/// Returns [quad] with corner [index] replaced by [point].
PageQuad replaceCorner(PageQuad quad, int index, NormalisedPoint point) =>
    switch (index) {
      0 => quad.copyWith(topLeft: point),
      1 => quad.copyWith(topRight: point),
      2 => quad.copyWith(bottomRight: point),
      _ => quad.copyWith(bottomLeft: point),
    };
