import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/player_stats.dart';

class PlayerStatsRadarChart extends StatelessWidget {
  final PlayerStats stats;
  final Map<String, Color> labelColors;

  const PlayerStatsRadarChart({
    super.key,
    required this.stats,
    this.labelColors = const {},
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: RadarChartPainter(
        stats: stats,
        primaryColor: Theme.of(context).primaryColor,
        labelColors: labelColors,
      ),
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final PlayerStats stats;
  final Color primaryColor;
  final Map<String, Color> labelColors;

  RadarChartPainter({
    required this.stats,
    required this.primaryColor,
    this.labelColors = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(center.dx, center.dy) * 0.8;
    
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
        ..color = Colors.white.withOpacity(0.1)
        ..style = PaintingStyle.fill
    );
    
    // Draw web lines and circles
    for (int i = 0; i < 4; i++) {
      final webRadius = radius * (0.25 * (i + 1));
      _drawPolygon(canvas, center, webRadius, sides, angle, 1.0, 
        Paint()
          ..color = Colors.white.withOpacity(0.2)
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
          ..color = Colors.white.withOpacity(0.2)
          ..strokeWidth = 1.0
      );
    }
    
    // Draw stats polygon with gradient
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF00F5A0).withOpacity(0.7),
          const Color(0xFF00D9F5).withOpacity(0.7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCenter(
        center: center,
        width: radius * 2,
        height: radius * 2,
      ))
      ..style = PaintingStyle.fill;
    
    _drawPolygon(canvas, center, radius, sides, angle, 1.0, 
      gradientPaint,
      values: values
    );
    
    // Draw stats border
    _drawPolygon(canvas, center, radius, sides, angle, 1.0, 
      Paint()
        ..color = Colors.white
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
      
      // Draw glowing point
      for (double j = 4; j >= 0; j--) {
        canvas.drawCircle(
          Offset(x, y),
          j + 2,
          Paint()
            ..color = _getPointColor(i).withOpacity(0.3 - (j * 0.05))
            ..style = PaintingStyle.fill
        );
      }
      
      // Draw center point
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()
          ..color = _getPointColor(i)
          ..style = PaintingStyle.fill
      );
    }
    
    // Draw attribute labels
    final labelPaint = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    final labels = ['PACE', 'SHOOTING', 'PASSING', 'DRIBBLING', 'DEFENSE', 'PHYSICAL'];
    
    for (int i = 0; i < sides; i++) {
      final currentAngle = angle * i - math.pi / 2;
      final x = center.dx + (radius + 22) * math.cos(currentAngle);
      final y = center.dy + (radius + 22) * math.sin(currentAngle);
      
      // Choose color for label
      final color = labelColors[labels[i]] ?? Colors.white;
      
      final labelStyle = TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            blurRadius: 5,
            color: color.withOpacity(0.7),
            offset: const Offset(0, 0),
          )
        ],
      );
      
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
      
      // Draw value number next to each point
      final valueText = (values[i] * 100).toInt().toString();
      
      final valuePaint = TextPainter(
        text: TextSpan(
          text: valueText,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      valuePaint.layout();
      
      final valueX = center.dx + (radius * 0.75) * values[i] * math.cos(currentAngle);
      final valueY = center.dy + (radius * 0.75) * values[i] * math.sin(currentAngle);
      
      valuePaint.paint(
        canvas, 
        Offset(
          valueX - valuePaint.width / 2,
          valueY - valuePaint.height / 2,
        ),
      );
    }
  }
  
  Color _getPointColor(int index) {
    final labels = ['PACE', 'SHOOTING', 'PASSING', 'DRIBBLING', 'DEFENSE', 'PHYSICAL'];
    return labelColors[labels[index]] ?? Color(0xFF00F5A0);
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
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.labelColors != labelColors;
} 