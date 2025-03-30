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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Text(
                      "This app helps you become a better football player! Track your skills, take fun tests, and complete exciting challenges.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Colorful features section
                  _buildColorfulTitle('COOL FEATURES!'),
                  
                  const SizedBox(height: 20),
                  
                  // Feature cards in a grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildFeatureCard(
                        title: 'Player Cards',
                        icon: Icons.credit_card,
                        color: Colors.blue,
                        isAnimated: true,
                      ),
                      _buildFeatureCard(
                        title: 'Fun Tests',
                        icon: Icons.fitness_center,
                        color: Colors.green,
                        isAnimated: true,
                      ),
                      _buildFeatureCard(
                        title: 'Challenges',
                        icon: Icons.emoji_events,
                        color: Colors.amber,
                        isAnimated: true,
                      ),
                      _buildFeatureCard(
                        title: 'Track Progress',
                        icon: Icons.show_chart,
                        color: Colors.purple,
                        isAnimated: true,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Mascot character with speech bubble
                  _buildMascotSection(),
                  
                  const SizedBox(height: 30),
                  
                  // Football Field with skills
                  _buildFootballField(),
                  
                  const SizedBox(height: 30),
                  
                  // Cool Achievements section
                  _buildAchievementsSection(),
                  
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
  
  Widget _buildColorfulTitle(String title) {
    // Create a gradient text effect
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.red, Colors.yellow, Colors.green, Colors.blue, Colors.purple],
      ).createShader(bounds),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 2,
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
  
  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    bool isAnimated = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: isAnimated 
                ? color.withOpacity(0.4) 
                : color.withOpacity(0.2),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.8, end: isAnimated ? 1.2 : 1.0),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 60,
                        ),
                      );
                    },
                    onEnd: () {
                      if (isAnimated && mounted) {
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: color.withOpacity(0.7),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getFeatureDescription(title),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  String _getFeatureDescription(String title) {
    switch (title) {
      case 'Player Cards':
        return 'Create your own football player card with your skills and photo';
      case 'Fun Tests':
        return 'Take tests to measure your speed, passing, shooting and more';
      case 'Challenges':
        return 'Complete fun challenges to improve your skills and earn badges';
      case 'Track Progress':
        return 'See how your football skills improve over time';
      default:
        return '';
    }
  }
  
  Widget _buildMascotSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.amber.withOpacity(0.5),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated football character
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.9, end: 1.1),
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.sports_soccer,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
            onEnd: () => setState(() {}),
          ),
          const SizedBox(width: 16),
          
          // Speech bubble with animated text
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Hi! I'm Footy!",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B0057),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "I'll help you improve your football skills with fun tests and challenges!",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3D007A),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFootballField() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Skills You Will Learn',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B0057),
            ),
          ),
        ),
        Container(
          height: 250,
          decoration: BoxDecoration(
            color: Colors.green.shade800,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // Field markings
              Positioned.fill(
                child: CustomPaint(
                  painter: FootballFieldPainter(),
                ),
              ),
              
              // Skills positions
              Positioned(
                left: 40,
                top: 70,
                child: _buildSkillBubble('Passing', Colors.blue),
              ),
              Positioned(
                right: 40,
                top: 70,
                child: _buildSkillBubble('Shooting', Colors.red),
              ),
              Positioned(
                left: 70,
                bottom: 70,
                child: _buildSkillBubble('Control', Colors.orange),
              ),
              Positioned(
                right: 70,
                bottom: 70,
                child: _buildSkillBubble('Speed', Colors.purple),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 50,
                child: Center(
                  child: _buildSkillBubble('Dribbling', Colors.teal),
                ),
              ),
              
              // Animated football
              AnimatedPositioned(
                duration: const Duration(seconds: 3),
                curve: Curves.easeInOut,
                left: 20 + (math.Random().nextDouble() * 300),
                top: 50 + (math.Random().nextDouble() * 150),
                onEnd: () {
                  if (mounted) setState(() {});
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sports_soccer,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSkillBubble(String skill, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        skill,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
  
  Widget _buildAchievementsSection() {
    return Column(
      children: [
        _buildColorfulTitle('ACHIEVEMENTS'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          margin: const EdgeInsets.only(bottom: 15, top: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Complete challenges to earn these badges!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAchievementBadge(
              icon: Icons.star,
              color: Colors.amber,
              title: 'Star Player',
            ),
            _buildAchievementBadge(
              icon: Icons.military_tech,
              color: Colors.blue,
              title: 'Top Scorer',
            ),
            _buildAchievementBadge(
              icon: Icons.workspace_premium,
              color: Colors.purple,
              title: 'MVP',
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildAchievementBadge({
    required IconData icon,
    required Color color,
    required String title,
  }) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: 3,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 50,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
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