import 'package:flutter/material.dart';

enum _DoodleStyle { curl, wave, zigzag, swirl, lightning }

/// A hand-drawn style decorative line widget.
///
/// - [DashboardDoodleDivider.curl] — looping script squiggle for the
///   spending card (below the amount).
/// - [DashboardDoodleDivider.wave] — wide flowing S-curve with uneven crests
///   (hand-sketched, not a perfect sine).
/// - [DashboardDoodleDivider.zigzag] — tight hand-drawn underline with small
///   peaks for transaction date group headers.
/// - [DashboardDoodleDivider.swirl] — loose coil / loop-de-loop for the DUE NOW
///   card bottom-right corner.
/// - [DashboardDoodleDivider.lightning] — jagged hand-drawn bolt accent.
class DashboardDoodleDivider extends StatelessWidget {
  /// Looping script curl — spending card, below the amount.
  const DashboardDoodleDivider.curl({
    super.key,
    this.color = Colors.black26,
  }) : _style = _DoodleStyle.curl;

  /// Wide flowing S-curve wave.
  const DashboardDoodleDivider.wave({
    super.key,
    this.color = Colors.black26,
  }) : _style = _DoodleStyle.wave;

  /// Tight hand-drawn zigzag underline — transaction date headers.
  const DashboardDoodleDivider.zigzag({
    super.key,
    this.color = Colors.black26,
  }) : _style = _DoodleStyle.zigzag;

  /// Hand-drawn spiral coil — DUE NOW card, bottom-right.
  const DashboardDoodleDivider.swirl({
    super.key,
    this.color = Colors.black26,
  }) : _style = _DoodleStyle.swirl;

  /// Irregular zigzag bolt — Upcoming card header accent.
  const DashboardDoodleDivider.lightning({
    super.key,
    this.color = Colors.black26,
  }) : _style = _DoodleStyle.lightning;

  final Color color;
  final _DoodleStyle _style;

  @override
  Widget build(BuildContext context) {
    final size = switch (_style) {
      _DoodleStyle.curl => const Size(72, 20),
      _DoodleStyle.wave => const Size(88, 22),
      _DoodleStyle.zigzag => const Size(80, 12),
      _DoodleStyle.swirl => const Size(52, 48),
      _DoodleStyle.lightning => const Size(130, 32),
    };

    return CustomPaint(
      size: size,
      painter: _DoodlePainter(color: color, style: _style),
    );
  }
}

class _DoodlePainter extends CustomPainter {
  _DoodlePainter({required this.color, required this.style});

  final Color color;
  final _DoodleStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = switch (style) {
      _DoodleStyle.wave => 1.6,
      _ => 2.0,
    };
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (style) {
      case _DoodleStyle.curl:
        _drawCurl(canvas, size, paint);
      case _DoodleStyle.wave:
        _drawWave(canvas, size, paint);
      case _DoodleStyle.zigzag:
        _drawZigzag(canvas, size, paint);
      case _DoodleStyle.swirl:
        _drawSwirl(canvas, size, paint);
      case _DoodleStyle.lightning:
        _drawLightning(canvas, size, paint);
    }
  }

  /// Script loops — two overlapping cursive loops with a trailing tail,
  /// like a hand-written "ee" flourish.
  void _drawCurl(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;

    final path = Path();
    path.moveTo(0, h * 0.60);
    // First loop: rises, curls over, dips below midline, tightens back
    path.cubicTo(w * 0.08, -h * 0.10, w * 0.28, -h * 0.10, w * 0.30, h * 0.52);
    path.cubicTo(w * 0.32, h * 1.00, w * 0.16, h * 1.05, w * 0.10, h * 0.72);
    // Bridge rises into second loop
    path.cubicTo(w * 0.05, h * 0.45, w * 0.38, -h * 0.15, w * 0.56, h * 0.50);
    path.cubicTo(w * 0.64, h * 0.95, w * 0.50, h * 1.05, w * 0.44, h * 0.78);
    // Trailing tail sweeps right
    path.cubicTo(w * 0.38, h * 0.55, w * 0.72, h * 0.20, w * 1.00, h * 0.48);

    canvas.drawPath(path, paint);
  }

  /// Flowing wave — three cubic segments with uneven span and crest depth so it
  /// reads like a quick pen sketch, not a repeating pattern.
  void _drawWave(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;

    final path = Path();
    path.moveTo(0, h * 0.53);
    path.cubicTo(
      w * 0.11,
      h * 0.02,
      w * 0.21,
      -h * 0.04,
      w * 0.31,
      h * 0.47,
    );
    path.cubicTo(
      w * 0.41,
      h * 1.04,
      w * 0.54,
      h * 0.92,
      w * 0.62,
      h * 0.51,
    );
    path.cubicTo(
      w * 0.72,
      h * 0.08,
      w * 0.88,
      h * 0.05,
      w * 1.00,
      h * 0.46,
    );

    canvas.drawPath(path, paint);
  }

  /// Hand-drawn zigzag underline — five shallow peaks with slightly uneven
  /// heights to give an organic, sketched feel.
  void _drawZigzag(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;

    // Peak offsets (y) are intentionally uneven for a hand-drawn look
    final peaks = [
      Offset(w * 0.10, h * 0.0),
      Offset(w * 0.30, h * 1.0),
      Offset(w * 0.50, h * 0.05),
      Offset(w * 0.70, h * 0.95),
      Offset(w * 0.90, h * 0.10),
    ];

    final path = Path();
    path.moveTo(0, h * 0.50);

    for (final peak in peaks) {
      path.quadraticBezierTo(
        peak.dx,
        peak.dy,
        peak.dx + w * 0.10,
        h * 0.50,
      );
    }

    canvas.drawPath(path, paint);
  }

  /// Jagged lightning sketch — uneven segment lengths and angles (not symmetric).
  void _drawLightning(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;

    final boltPaint =
        Paint()
          ..color = paint.color
          ..strokeWidth = paint.strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.miter
          ..strokeMiterLimit = 4;

    final path = Path()..moveTo(w * 0.02, h * 0.22);
    path.lineTo(w * 0.15, h * 0.82);
    path.lineTo(w * 0.24, h * 0.40);
    path.lineTo(w * 0.33, h * 0.92);
    path.lineTo(w * 0.48, h * 0.48);
    path.lineTo(w * 0.56, h * 0.78);
    path.lineTo(w * 0.66, h * 0.34);
    path.lineTo(w * 0.78, h * 0.86);
    path.lineTo(w * 0.88, h * 0.38);
    path.quadraticBezierTo(w * 0.96, h * 0.58, w * 0.99, h * 0.52);

    canvas.drawPath(path, boltPaint);
  }

  /// Loose inward coil scribble — anchored toward bottom-right of the box.
  void _drawSwirl(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;

    final path = Path();
    path.moveTo(w * 1.05, h * 0.58);
    path.cubicTo(
      w * 0.62, h * 1.05,
      w * 0.22, h * 0.55,
      w * 0.48, h * 0.22,
    );
    path.cubicTo(
      w * 0.72, -h * 0.08,
      w * 1.08, h * 0.18,
      w * 0.88, h * 0.48,
    );
    path.cubicTo(
      w * 0.68, h * 0.74,
      w * 0.48, h * 0.48,
      w * 0.62, h * 0.30,
    );
    path.cubicTo(
      w * 0.78, h * 0.12,
      w * 0.92, h * 0.35,
      w * 0.72, h * 0.52,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DoodlePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.style != style;
}
