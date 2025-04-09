import 'package:flutter/material.dart';
import 'dart:math' as math;

// --- RADAR GRAPHIC WIDGET ---
class BackgroundRadarGraphic extends StatelessWidget {
  const BackgroundRadarGraphic({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: 0.08, // Make it very subtle
        child: CustomPaint(
          size: Size(MediaQuery.of(context).size.width * 0.8, MediaQuery.of(context).size.width * 0.8),
          painter: _RadarPainter(),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = Colors.white // Use white for the lines
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const int ticks = 6; // Number of stats (hexagon points)
    const double angle = (2 * math.pi) / ticks;

    // Draw connecting lines (spokes)
    for (int i = 0; i < ticks; i++) {
      final x = center.dx + radius * math.cos(angle * i - math.pi / 2);
      final y = center.dy + radius * math.sin(angle * i - math.pi / 2);
      canvas.drawLine(center, Offset(x, y), paint);
    }

    // Draw outline polygons (web)
    const int levels = 4; // Number of web levels
    for (int level = 1; level <= levels; level++) {
      final path = Path();
      final levelRadius = radius * (level / levels);

      for (int i = 0; i < ticks; i++) {
        final x = center.dx + levelRadius * math.cos(angle * i - math.pi / 2);
        final y = center.dy + levelRadius * math.sin(angle * i - math.pi / 2);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- PITCH GRAPHIC WIDGET ---
class BottomPitchGraphic extends StatelessWidget {
  const BottomPitchGraphic({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: AspectRatio(
        aspectRatio: 2 / 1, // Adjust aspect ratio as needed
        child: Opacity(
          opacity: 0.15, // Adjust opacity for subtlety
          child: CustomPaint(
            painter: _PitchPainter(),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height);
    final fieldWidth = size.width * 0.9;
    final fieldHeight = size.height * 0.8;
    final cornerRadius = fieldWidth * 0.1;

    final rect = Rect.fromCenter(
      center: center,
      width: fieldWidth,
      height: fieldHeight * 2, // We only see the bottom half
    );

    // Draw outer rounded rectangle boundary (only bottom half visible)
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius)),
      paint,
    );

    // Center line
    canvas.drawLine(
      Offset(rect.left, rect.center.dy),
      Offset(rect.right, rect.center.dy),
      paint,
    );

    // Center circle
    canvas.drawCircle(rect.center, fieldWidth * 0.15, paint);

    // Bottom penalty area (approximate)
    final bottomPenaltyRect = Rect.fromCenter(
      center: Offset(rect.center.dx, rect.bottom - fieldHeight * 0.2),
      width: fieldWidth * 0.5,
      height: fieldHeight * 0.4, // Only bottom part visible
    );
    canvas.drawRect(bottomPenaltyRect, paint);

    // Bottom goal area (approximate)
     final bottomGoalRect = Rect.fromCenter(
      center: Offset(rect.center.dx, rect.bottom - fieldHeight * 0.08),
      width: fieldWidth * 0.25,
      height: fieldHeight * 0.16, // Only bottom part visible
    );
     canvas.drawRect(bottomGoalRect, paint);

    // Bottom penalty arc (approximate)
    canvas.drawArc(
      Rect.fromCenter(center: Offset(rect.center.dx, bottomPenaltyRect.top), width: fieldWidth * 0.2, height: fieldWidth * 0.2),
      0, // Start angle
      math.pi, // Sweep angle (180 degrees)
      false,
      paint,
    );

     // Bottom corner arcs
    final cornerArcSize = cornerRadius * 2;
    canvas.drawArc(
      Rect.fromLTWH(rect.left, rect.bottom - cornerArcSize, cornerArcSize, cornerArcSize),
      math.pi / 2, // 90 degrees
      math.pi / 2, // 90 degrees sweep
      false,
      paint,
    );
     canvas.drawArc(
      Rect.fromLTWH(rect.right - cornerArcSize, rect.bottom - cornerArcSize, cornerArcSize, cornerArcSize),
      math.pi, // 180 degrees
      math.pi / 2, // 90 degrees sweep
      false,
      paint,
    );

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 