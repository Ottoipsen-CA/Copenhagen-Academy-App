import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/player_stats.dart';
import '../models/player_test.dart';
import '../services/player_tests_service.dart';

class PlayerStatsRadarChart extends StatefulWidget {
  final Map<String, Color> labelColors;
  final PlayerStats? playerStats;
  final PlayerTest? playerTest;
  final bool fetchData;
  final bool useLatestTest;

  const PlayerStatsRadarChart({
    super.key,
    this.labelColors = const {},
    this.playerStats,
    this.playerTest,
    this.fetchData = true,
    this.useLatestTest = false,
  });

  @override
  State<PlayerStatsRadarChart> createState() => _PlayerStatsRadarChartState();
}

class _PlayerStatsRadarChartState extends State<PlayerStatsRadarChart> {
  PlayerStats? _stats;
  bool _isLoading = true;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    
    // If stats are provided directly, use them
    if (widget.playerStats != null) {
      _stats = widget.playerStats;
      _isLoading = false;
    } 
    // If a test is provided, convert to stats
    else if (widget.playerTest != null) {
      _stats = _convertTestToStats(widget.playerTest!);
      _isLoading = false;
    }
    // If using latest test is requested, prioritize that
    else if (widget.useLatestTest) {
      // Initialize the service
      _loadLatestTestFromApi();
    }
    // Otherwise fetch stats if requested
    else if (widget.fetchData) {
      // Initialize the service
      PlayerTestsService.initialize(context);
      _loadStats();
    } else {
      // No data source provided and not fetching
      _stats = PlayerStats.empty();
      _isLoading = false;
    }
  }
  
  // Load the latest test directly from the API endpoint
  Future<void> _loadLatestTestFromApi() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Initialize the service if needed
      PlayerTestsService.initialize(context);
      
      // Get all tests from the API endpoint
      final tests = await PlayerTestsService.getPlayerTests(context);
      
      if (!mounted) return;
      
      if (tests.isNotEmpty) {
        // Sort tests by date (most recent first)
        tests.sort((a, b) {
          if (a.testDate == null) return 1;
          if (b.testDate == null) return -1;
          return b.testDate!.compareTo(a.testDate!);
        });
        
        // Use the most recent test
        final latestTest = tests.first;
        
        print('Latest test loaded: ${latestTest.testDate} with ID: ${latestTest.id}');
        print('Ratings - Pace: ${latestTest.paceRating}, Shooting: ${latestTest.shootingRating}');
        
        // Convert to stats for the radar chart
        final stats = _convertTestToStats(latestTest);
        
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      } else {
        // No tests found
        setState(() {
          _stats = PlayerStats.empty();
          _isLoading = false;
          _errorMessage = 'No test data available';
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      print('Error loading latest player test from API: $e');
      setState(() {
        _stats = PlayerStats.empty(); // Use empty stats when error occurs
        _isLoading = false;
        _errorMessage = 'Failed to load test data: $e';
      });
    }
  }
  
  // Convert a PlayerTest to PlayerStats for the radar chart
  PlayerStats _convertTestToStats(PlayerTest test) {
    return PlayerStats(
      pace: (test.paceRating ?? 50).toDouble(),
      shooting: (test.shootingRating ?? 50).toDouble(),
      passing: (test.passingRating ?? 50).toDouble(),
      dribbling: (test.dribblingRating ?? 50).toDouble(),
      juggles: (test.jugglesRating ?? 50).toDouble(),
      firstTouch: (test.firstTouchRating ?? 50).toDouble(),
      overallRating: test.overallRating != null ? test.overallRating!.toDouble() : test.getOverallRating().toDouble(),
      lastUpdated: test.testDate,
      lastTestId: test.id,
    );
  }
  
  Future<void> _loadStats() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final statsData = await PlayerTestsService.getPlayerStats(context);
      if (!mounted) return;
      
      if (statsData != null) {
        final stats = PlayerStats.fromJson(statsData);
        
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      } else {
        // Handle the case when statsData is null
        setState(() {
          _stats = PlayerStats.empty();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      print('Error loading player stats: $e');
      setState(() {
        _stats = PlayerStats.empty(); // Use empty stats when error occurs
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_errorMessage.isNotEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            _errorMessage,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    
    final stats = _stats ?? PlayerStats.empty();
    
    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: RadarChartPainter(
        stats: stats,
        primaryColor: Theme.of(context).primaryColor,
        labelColors: widget.labelColors,
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
    final values = <double>[
      (stats.pace ?? 0) / 100,
      (stats.shooting ?? 0) / 100,
      (stats.passing ?? 0) / 100,
      (stats.dribbling ?? 0) / 100,
      (stats.juggles ?? 0) / 100,
      (stats.firstTouch ?? 0) / 100,
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
      
      // Get color for the point
      final Color pointColor = _getPointColor(i);
      
      // Draw glowing point
      for (double j = 4; j >= 0; j--) {
        canvas.drawCircle(
          Offset(x, y),
          j + 2,
          Paint()
            ..color = pointColor.withOpacity(0.3 - (j * 0.05))
            ..style = PaintingStyle.fill
        );
      }
      
      // Draw center point
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()
          ..color = pointColor
          ..style = PaintingStyle.fill
      );
    }
    
    // Draw attribute labels
    final labelPaint = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    final labels = ['PACE', 'SHOOTING', 'PASSING', 'DRIBBLING', 'JUGGLES', 'FIRST TOUCH'];
    final rawValues = [
      stats.pace.toInt(),
      stats.shooting.toInt(),
      stats.passing.toInt(),
      stats.dribbling.toInt(),
      stats.juggles.toInt(),
      stats.firstTouch.toInt(),
    ];
    
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
      
      // Draw value number inside the radar chart at each point
      final valueText = rawValues[i].toString();
      
      final valuePaint = TextPainter(
        text: TextSpan(
          text: valueText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      valuePaint.layout();
      
      // Calculate position for value text to be displayed ON the point
      final valueX = center.dx + (radius * 0.7) * values[i] * math.cos(currentAngle);
      final valueY = center.dy + (radius * 0.7) * values[i] * math.sin(currentAngle);
      
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
    final labels = ['PACE', 'SHOOTING', 'PASSING', 'DRIBBLING', 'JUGGLES', 'FIRST TOUCH'];
    return labelColors[labels[index]] ?? const Color(0xFF00F5A0);
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