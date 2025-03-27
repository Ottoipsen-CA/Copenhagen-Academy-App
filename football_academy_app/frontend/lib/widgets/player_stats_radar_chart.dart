import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/player_stats.dart';

class PlayerStatsRadarChart extends StatelessWidget {
  final PlayerStats stats;

  const PlayerStatsRadarChart({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: RadarChartPainter(
        stats: stats,
        primaryColor: Theme.of(context).primaryColor,
      ),
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final PlayerStats stats;
  final Color primaryColor;

  RadarChartPainter({
    required this.stats,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(center.dx, center.dy) * 0.85;
    
    // Calculate values
    final values = [
      stats.pace / 100,
      stats.shooting / 100,
      stats.passing / 100,
      stats.dribbling / 100,
      stats.defense / 100,
      stats.physical / 100,
    ];
    
    // Calculate angles
    const sides = 6; // Hexagon for 6 attributes
    final angle = (2 * math.pi) / sides;
    
    // Draw background web
    _drawPolygon(canvas, center, radius, sides, angle, 1.0, 
      Paint()
        ..color = Colors.grey.shade200
        ..style = PaintingStyle.fill
    );
    
    // Draw web lines and circles
    for (int i = 0; i < 4; i++) {
      final webRadius = radius * (0.25 * (i + 1));
      _drawPolygon(canvas, center, webRadius, sides, angle, 1.0, 
        Paint()
          ..color = Colors.grey.shade300
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
      );
    }
    
    // Draw axis lines
    for (int i = 0; i < sides; i++) {
      final currentAngle = angle * i - math.pi / 2;
      final x = center.dx + radius * math.cos(currentAngle);
      final y = center.dy + radius * math.sin(currentAngle);
      
      canvas.drawLine(
        center,
        Offset(x, y),
        Paint()
          ..color = Colors.grey.shade300
          ..strokeWidth = 1.0
      );
    }
    
    // Draw stats polygon
    _drawPolygon(canvas, center, radius, sides, angle, 1.0, 
      Paint()
        ..color = primaryColor.withOpacity(0.2)
        ..style = PaintingStyle.fill,
      values: values
    );
    
    // Draw stats border
    _drawPolygon(canvas, center, radius, sides, angle, 1.0, 
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
      values: values
    );
    
    // Draw stat points
    for (int i = 0; i < sides; i++) {
      final currentAngle = angle * i - math.pi / 2;
      final value = values[i];
      final x = center.dx + radius * value * math.cos(currentAngle);
      final y = center.dy + radius * value * math.sin(currentAngle);
      
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()
          ..color = primaryColor
          ..style = PaintingStyle.fill
      );
    }
    
    // Draw attribute labels
    final labelPaint = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    final labels = ['PACE', 'SHOOTING', 'PASSING', 'DRIBBLING', 'DEFENSE', 'PHYSICAL'];
    final labelStyle = TextStyle(
      color: Colors.grey.shade700,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );
    
    for (int i = 0; i < sides; i++) {
      final currentAngle = angle * i - math.pi / 2;
      final x = center.dx + (radius + 15) * math.cos(currentAngle);
      final y = center.dy + (radius + 15) * math.sin(currentAngle);
      
      labelPaint.text = TextSpan(
        text: labels[i],
        style: labelStyle,
      );
      
      labelPaint.layout();
      
      labelPaint.paint(
        canvas, 
        Offset(
          x - labelPaint.width / 2,
          y - labelPaint.height / 2,
        ),
      );
    }
  }

  void _drawPolygon(
    Canvas canvas,
    Offset center,
    double radius,
    int sides,
    double angle,
    double startAngle,
    Paint paint, {
    List<double>? values,
  }) {
    final path = Path();
    final angleOffset = -math.pi / 2; // Start from top (pace)
    
    for (int i = 0; i < sides; i++) {
      final currentAngle = angle * i + angleOffset;
      final value = values != null ? values[i] : 1.0;
      final x = center.dx + radius * value * math.cos(currentAngle);
      final y = center.dy + radius * value * math.sin(currentAngle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(RadarChartPainter oldDelegate) => 
      oldDelegate.stats != stats ||
      oldDelegate.primaryColor != primaryColor;
} 