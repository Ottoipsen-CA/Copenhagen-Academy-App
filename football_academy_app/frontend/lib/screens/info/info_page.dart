import 'package:flutter/material.dart';
import '../../widgets/navigation_drawer.dart';
import 'dart:math' as math;

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _bounceAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Football Academy App', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0B0057),
      ),
      drawer: const CustomNavigationDrawer(currentPage: 'info'),
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
            // Animated stars background
            Positioned.fill(
              child: CustomPaint(
                painter: StarsPainter(),
              ),
            ),
            
            // Animated footballs
            for (int i = 0; i < 5; i++)
              AnimatedFootball(
                startPosition: Offset(
                  50.0 + (i * 70),
                  -50.0 - (i * 200.0),
                ),
                size: 40.0 + (i * 5),
                duration: Duration(seconds: 10 + i),
              ),
            
            // Main content
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Bouncing header
                  AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _bounceAnimation.value),
                        child: _buildHeader(context),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // App explanation section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Velkommen til Copenhagen Academy Beta!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Vi er glade for at du er med på vores fodboldudviklingsrejse! I denne beta-version kan du allerede:",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureBullet("Gennemføre spændende fodboldudfordringer"),
                        _buildFeatureBullet("Tage færdighedstests for at måle din fremgang"),
                        _buildFeatureBullet("Følge din udvikling over tid"),
                        const SizedBox(height: 16),
                        const Text(
                          "Vi arbejder hårdt på at bringe flere funktioner snart, herunder avancerede træningsplaner, videotutorials og flere challenges. Hold dig opdateret!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Detailed feature descriptions
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Dine Fodboldfærdigheder",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureDescription(
                          "FIFA-Style Spillerkort",
                          "Dit personlige FIFA-kort opdateres automatisk efter din test. Jo bedre du præsterer, jo højere tal får du. Træn mere end dine venner og kæmp dig til toppen!.",
                          Icons.credit_card,
                          Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureDescription(
                          "Radar Chart",
                          "Få et visuelt overblik over dine styrker og svagheder. Radar chartet viser dine resultater på tværs af alle tekniske områder, så du ved præcis, hvor du skal forbedre dig.",
                          Icons.radar,
                          Colors.purple,
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureDescription(
                          "Færdighedstests",
                          "Gennemfør præcise tests for at måle dine fodboldfærdigheder:",
                          Icons.fitness_center,
                          Colors.green,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTestBullet("Sprint Test - Mål din hastighed"),
                              _buildTestBullet("Skud Test - Test din præcision"),
                              _buildTestBullet("Pasning Test - Test din teknik"),
                              _buildTestBullet("Dribling Test - Test din boldkontrol"),
                              _buildTestBullet("Jonglering Test - Test din Jongleringer"),
                              _buildTestBullet("Første Berøring Test - Test dine førsteberøringer"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.copyright,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${DateTime.now().year} Copenhagen Academy',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // Logo with pulsating effect
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.9, end: 1.1),
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.6),
                      blurRadius: 25,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'CA',
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B0057),
                    ),
                  ),
                ),
              ),
            );
          },
          onEnd: () => setState(() {}),
        ),
        const SizedBox(height: 16),
        const Text(
          'COPENHAGEN ACADEMY',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.orange, Colors.pink],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Text(
            'Football Skills Tracker!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Train, test, and track your football skills!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFeatureBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.greenAccent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureDescription(String title, String description, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTestBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.sports_soccer,
            color: Colors.greenAccent,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedFootball extends StatefulWidget {
  final Offset startPosition;
  final double size;
  final Duration duration;

  const AnimatedFootball({
    super.key,
    required this.startPosition,
    required this.size,
    required this.duration,
  });

  @override
  State<AnimatedFootball> createState() => _AnimatedFootballState();
}

class _AnimatedFootballState extends State<AnimatedFootball> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Offset _position;

  @override
  void initState() {
    super.initState();
    _position = widget.startPosition;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        setState(() {
          // Move the football down the screen
          _position = Offset(
            widget.startPosition.dx + math.sin(_animation.value * 10) * 30,
            widget.startPosition.dy + _animation.value * 1000,
          );
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reset();
          _controller.forward();
        }
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: Transform.rotate(
        angle: _animation.value * 10,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            Icons.sports_soccer,
            size: widget.size * 0.8,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class FootballFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw outline
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );

    // Draw center line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    // Draw center circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.height / 5,
      paint,
    );

    // Draw small center circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      5,
      Paint()..color = Colors.white,
    );

    // Draw goal areas
    final goalAreaWidth = size.width / 6;
    final goalAreaHeight = size.height / 4;

    // Left goal area
    canvas.drawRect(
      Rect.fromLTWH(0, (size.height - goalAreaHeight) / 2, goalAreaWidth, goalAreaHeight),
      paint,
    );

    // Right goal area
    canvas.drawRect(
      Rect.fromLTWH(size.width - goalAreaWidth, (size.height - goalAreaHeight) / 2, goalAreaWidth, goalAreaHeight),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    // Draw 150 random stars with varying sizes
    for (int i = 0; i < 150; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2.0;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 