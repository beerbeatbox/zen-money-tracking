import 'package:flutter/material.dart';

enum _DoodleStyle { curl, wave, zigzag, swirl }

/// A hand-drawn style decorative line widget.
///
/// - [DashboardDoodleDivider.curl] — looping script squiggle for the
///   spending card (below the amount).
/// - [DashboardDoodleDivider.wave] — wide flowing S-curve (generic accent).
/// - [DashboardDoodleDivider.zigzag] — tight hand-drawn underline with small
///   peaks for transaction date group headers.
/// - [DashboardDoodleDivider.swirl] — loose coil / loop-de-loop for the DUE NOW
///   card bottom-right corner.
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

  final Color color;
  final _DoodleStyle _style;

  @override
  Widget build(BuildContext context) {
    final size = switch (_style) {
      _DoodleStyle.curl => const Size(72, 20),
      _DoodleStyle.wave => const Size(130, 32),
      _DoodleStyle.zigzag => const Size(80, 12),
      _DoodleStyle.swirl => const Size(52, 48),
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
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
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

  /// Smooth sine-like wave — three S-curve segments flowing left to right.
  void _drawWave(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;

    final path = Path();
    path.moveTo(0, h * 0.50);
    path.cubicTo(w * 0.10, h * 0.0,  w * 0.23, h * 0.0,  w * 0.33, h * 0.50);
    path.cubicTo(w * 0.43, h * 1.0,  w * 0.57, h * 1.0,  w * 0.67, h * 0.50);
    path.cubicTo(w * 0.77, h * 0.0,  w * 0.90, h * 0.0,  w * 1.00, h * 0.50);

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
