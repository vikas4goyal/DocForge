/// The crop screen and its draggable edge overlay.
library;

import 'dart:io';

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
            Positioned.fill(child: _CropCanvas(state: state)),
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
class _CropCanvas extends StatelessWidget {
  const _CropCanvas({required this.state});

  final CropState state;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(state.page.imagePath),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const ColoredBox(color: Colors.black12),
            ),
            CustomPaint(
              key: ScanKeys.edgeOverlay,
              painter: _QuadPainter(
                quad: state.quad,
                colour: Theme.of(context).colorScheme.primary,
              ),
            ),
            for (var corner = 0; corner < 4; corner++)
              _CornerHandle(
                corner: corner,
                quad: state.quad,
                canvasSize: size,
                enabled: !state.isWorking,
              ),
          ],
        );
      },
    );
  }
}

/// Draws the crop quadrilateral.
class _QuadPainter extends CustomPainter {
  const _QuadPainter({required this.quad, required this.colour});

  final PageQuad quad;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      for (final corner in quad.corners)
        Offset(corner.x * size.width, corner.y * size.height),
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
  }

  @override
  bool shouldRepaint(_QuadPainter oldDelegate) =>
      oldDelegate.quad != quad || oldDelegate.colour != colour;
}

/// One draggable corner of the crop.
class _CornerHandle extends StatelessWidget {
  const _CornerHandle({
    required this.corner,
    required this.quad,
    required this.canvasSize,
    required this.enabled,
  });

  final int corner;
  final PageQuad quad;
  final Size canvasSize;
  final bool enabled;

  /// Visual radius of a handle.
  static const _radius = 12.0;

  @override
  Widget build(BuildContext context) {
    final point = quad.corners[corner];
    final centre = Offset(
      point.x * canvasSize.width,
      point.y * canvasSize.height,
    );

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
            onPanUpdate: enabled
                ? (details) => _drag(context, details.delta)
                : null,
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

  /// Moves this corner by [delta] pixels.
  ///
  /// Clamped to the image: a corner dragged outside it would describe a crop
  /// of pixels that do not exist, which the transform would then have to guess
  /// at.
  void _drag(BuildContext context, Offset delta) {
    final point = quad.corners[corner];
    final moved = NormalisedPoint(
      x: (point.x + delta.dx / canvasSize.width).clamp(0.0, 1.0),
      y: (point.y + delta.dy / canvasSize.height).clamp(0.0, 1.0),
    );

    context.read<CropCubit>().adjust(_replace(quad, corner, moved));
  }

  static String _labelFor(int corner) => switch (corner) {
    0 => 'Top left crop handle',
    1 => 'Top right crop handle',
    2 => 'Bottom right crop handle',
    _ => 'Bottom left crop handle',
  };

  /// Returns [quad] with corner [index] replaced by [point].
  static PageQuad _replace(PageQuad quad, int index, NormalisedPoint point) =>
      switch (index) {
        0 => quad.copyWith(topLeft: point),
        1 => quad.copyWith(topRight: point),
        2 => quad.copyWith(bottomRight: point),
        _ => quad.copyWith(bottomLeft: point),
      };
}
