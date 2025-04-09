import 'package:flutter/material.dart';
import '../../widgets/player_test_widget.dart';
import '../../widgets/navigation_drawer.dart';
import 'dart:math';

class PlayerTestsPage extends StatelessWidget {
  const PlayerTestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40), // Smaller app bar
        child: AppBar(
          title: const Text(
            'Spillertest',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF0B0057),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      drawer: const CustomNavigationDrawer(currentPage: 'tests'),
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B0057), // Dark blue/purple
              Color(0xFF1C006C), // Mid purple
              Color(0xFF3D007A), // Lighter purple
            ],
          ),
        ),
        child: Stack(
          children: [
            // Stars background
            Positioned.fill(
              child: CustomPaint(
                painter: StarsPainter(),
              ),
            ),
            
            // Main content
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  8.0, // Reduced side padding
                  4.0, // Reduced top padding
                  8.0, // Reduced side padding
                  MediaQuery.of(context).viewInsets.bottom + 4.0, // Reduced bottom padding
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Compact header
                    Row(
                      children: [
                        const Icon(
                          Icons.sports_score,
                          color: Colors.white,
                          size: 16, // Smaller icon
                        ),
                        const SizedBox(width: 4), // Reduced spacing
                        const Text(
                          'Dine færdigheder',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14, // Smaller text
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4), // Reduced spacing
                    
                    // Player test widget in Expanded to take remaining space
                    const Expanded(
                      child: PlayerTestWidget(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// StarsPainter for the background effect
class StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // Calculate number of stars based on size
    final starCount = (size.width * size.height / 1000).round().clamp(50, 200);
    
    // Use a random seed for reproducibility
    final random = Random(42);
    
    // Draw random stars
    for (var i = 0; i < starCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 0.5 + random.nextDouble() * 1.5; // Random star size
      
      // Vary star brightness
      paint.color = Colors.white.withOpacity(0.3 + random.nextDouble() * 0.7);
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
} 