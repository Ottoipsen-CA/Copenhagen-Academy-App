import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:math';
import '../../models/auth.dart';
import '../../services/auth_service.dart';
import '../../theme/colors.dart';
import '../dashboard/dashboard_page.dart';
import 'register_page.dart';
import '../../services/challenge_service.dart';
import '../info/info_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../widgets/fifa_player_card.dart';
import '../../models/player_stats.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../../widgets/decorative_backgrounds.dart';

// Platform-specific imports
import 'package:universal_html/html.dart' if (dart.library.io) 'dart:io';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Animation state
  late AnimationController _starController;
  List<_FallingStar> _stars = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initializeStars();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _starController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      await authService.login(
        LoginRequest(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
      
      if (!mounted) return;
      
      // Initialize challenges for the user after successful login
      await ChallengeService.initializeUserChallenges();
      
      // Navigate to dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const DashboardPage(),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Ugyldig email eller adgangskode. Prøv igen.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    // No longer needed - removed profile image functionality
  }

  // --- STAR ANIMATION LOGIC ---
  void _initializeStars() {
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16 * 500),
    )..addListener(_updateStars)..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) { 
      if (!mounted) return;
      final screenHeight = MediaQuery.of(context).size.height;
      final screenWidth = MediaQuery.of(context).size.width;
      const int starCount = 70;

      _stars = List.generate(starCount, (index) {
        return _FallingStar(
          x: _random.nextDouble() * screenWidth,
          y: _random.nextDouble() * screenHeight,
          size: _random.nextDouble() * 2.5 + 1.5,
          speed: _random.nextDouble() * 1.5 + 0.5,
          opacity: _random.nextDouble() * 0.5 + 0.3,
        );
      });
    });
  }

  void _updateStars() {
    if (!mounted) return;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    setState(() {
      for (var star in _stars) {
        star.y += star.speed;
        if (star.y > screenHeight + star.size) {
          star.y = -star.size;
          star.x = _random.nextDouble() * screenWidth;
          star.size = _random.nextDouble() * 2.5 + 1.5;
          star.speed = _random.nextDouble() * 1.5 + 0.5;
          star.opacity = _random.nextDouble() * 0.5 + 0.3;
        }
      }
    });
  }
  // --- END STAR ANIMATION LOGIC ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B0033),
              Color(0xFF2A004D),
              Color(0xFF5D006C),
              Color(0xFF9A0079),
              Color(0xFFC71585),
              Color(0xFFFF4500),
            ],
            stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // --- STAR ANIMATION LAYER ---
              AnimatedBuilder(
                animation: _starController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: FallingStarsPainter(stars: _stars),
                    child: Container(), // Needs a child to render
                  );
                },
              ),
              // --- END STAR ANIMATION LAYER ---
              const BackgroundRadarGraphic(),
              const BottomPitchGraphic(),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isLandscape = constraints.maxWidth > 600;
                  final isSmallScreen = constraints.maxWidth < 360;
                  
                  if (isLandscape) {
                    return _buildLandscapeLayout();
                  } else {
                    return _buildPortraitLayout(isSmallScreen);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLandscapeLayout() {
    return Column(
      children: [
        _buildAppHeader(),
        Expanded(
          child: Row(
            children: [
              // Left side: Player card
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: SizedBox(
                      width: 300,
                      child: _buildPlayerCard(),
                    ),
                  ),
                ),
              ),
              
              // Right side: Login form and text
              Expanded(
                flex: 7,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      _buildMissionText(isSmallScreen: false),
                      const SizedBox(height: 30),
                      _buildLoginForm(),
                      const SizedBox(height: 20),
                      _buildSignUpSection(),
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const InfoPage(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.info_outline,
                            color: Colors.white70,
                            size: 20,
                          ),
                          label: const Text(
                            'Læs mere om Copenhagen Academy',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            backgroundColor: Colors.white.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPortraitLayout(bool isSmallScreen) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAppHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Player card
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.3,
                    child: Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: _buildPlayerCard(),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Mission text
                  _buildMissionText(isSmallScreen: isSmallScreen),
                  
                  const SizedBox(height: 24),
                  
                  // Login form
                  _buildLoginForm(),
                  
                  const SizedBox(height: 16),
                  
                  // Sign up section
                  _buildSignUpSection(),
                  
                  const SizedBox(height: 16),
                  
                  // Info button
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InfoPage(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.info_outline,
                        color: Colors.white70,
                        size: 20,
                      ),
                      label: const Text(
                        'Læs mere om Copenhagen Academy',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        backgroundColor: Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAppHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, color: Colors.amber[300], size: 22),
              const SizedBox(width: 8),
              Text(
                "COPENHAGEN ACADEMY",
                style: TextStyle(
                  color: Colors.amber[300],
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.emoji_events, color: Colors.amber[300], size: 22),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBadgeIcon(Icons.military_tech, Colors.amber),
              _buildBadgeIcon(Icons.sports_soccer, Colors.white),
              _buildBadgeIcon(Icons.star, Colors.amber),
              _buildBadgeIcon(Icons.sports_soccer, Colors.white),
              _buildBadgeIcon(Icons.military_tech, Colors.amber),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildBadgeIcon(IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(icon, color: color, size: 16),
    );
  }
  
  Widget _buildPlayerCard() {
    // Create dummy player stats for the login page
    final dummyStats = PlayerStats(
      pace: 94,
      shooting: 93,
      passing: 88,
      dribbling: 94,
      juggles: 92,
      firstTouch: 95
    );
    
    return FifaPlayerCard(
      playerName: "C. RONALDO",
      position: "ST",
      stats: dummyStats,
      rating: 93,
      cardType: CardType.normal,
      width: 300,
    );
  }
  
  Widget _buildMissionText({required bool isSmallScreen}) {
    final fontSize = isSmallScreen ? 28.0 : 32.0;
    final iconSize = isSmallScreen ? 24.0 : 28.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Træn",
              style: TextStyle(
                color: Colors.yellow,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.sports_soccer, color: Colors.amber[300], size: iconSize),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Flexible(
              child: Text(
                "og bliv stjernen på holdet!",
                style: TextStyle(
                  color: Colors.yellow,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.emoji_events, color: Colors.amber[300], size: iconSize),
          ],
        ),
      ],
    );
  }
  
  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF1E22AA),
                width: 3,
              ),
            ),
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: "Email",
                hintStyle: TextStyle(color: Colors.grey),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: InputBorder.none,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Indtast din email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Indtast en gyldig email';
                }
                return null;
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Password field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF1E22AA),
                width: 3,
              ),
            ),
            child: TextFormField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: "Adgangskode",
                hintStyle: TextStyle(color: Colors.grey),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: InputBorder.none,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Indtast din adgangskode';
                }
                return null;
              },
            ),
          ),
          
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Login button
          Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1E22AA),
                  Color(0xFF3F25BB),
                ],
              ),
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'LOG IND',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSignUpSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Har du ikke en bruger? ",
          style: TextStyle(
            color: Colors.yellow.shade200,
            fontSize: 16,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const RegisterPage(),
              ),
            );
          },
          child: const Text(
            'Opret en her',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.yellow,
            ),
          ),
        ),
      ],
    );
  }
}

// Simple class to hold star properties
class _FallingStar {
  double x;
  double y;
  double size;
  double speed;
  double opacity;

  _FallingStar({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

// --- CUSTOM PAINTER FOR FALLING STARS ---
class FallingStarsPainter extends CustomPainter {
  final List<_FallingStar> stars;

  FallingStarsPainter({required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    final goldPaint = Paint();

    for (var star in stars) {
      // Create a gradient for a shimmer effect
      final rect = Rect.fromCircle(center: Offset(star.x, star.y), radius: star.size);
      goldPaint.shader = RadialGradient(
        colors: [
          Colors.yellow[200]!.withOpacity(star.opacity),
          Colors.amber[600]!.withOpacity(star.opacity * 0.8),
          Colors.amber[900]!.withOpacity(star.opacity * 0.5),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
      
      // Draw star (simple circle for performance)
      canvas.drawCircle(Offset(star.x, star.y), star.size, goldPaint);
    }
  }

  @override
  bool shouldRepaint(covariant FallingStarsPainter oldDelegate) {
    return true; 
  }
}

// --- END CUSTOM PAINTER --- 