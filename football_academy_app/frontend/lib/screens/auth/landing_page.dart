import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';
import '../info/info_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B0057), // Dark purple
              Color(0xFF3D007A), // Medium purple
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative soccer balls in the background
              Positioned(
                top: 50,
                right: 30,
                child: _buildDecorativeIcon(
                  Icons.sports_soccer,
                  size: 40,
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              Positioned(
                bottom: 200,
                left: 20,
                child: _buildDecorativeIcon(
                  Icons.sports_soccer,
                  size: 30,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
              Positioned(
                top: 150,
                left: 40,
                child: _buildDecorativeIcon(
                  Icons.sports_soccer,
                  size: 25,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              
              // Decorative trophies
              Positioned(
                top: 100,
                right: 80,
                child: _buildDecorativeIcon(
                  Icons.emoji_events,
                  size: 35,
                  color: Colors.amber.withOpacity(0.3),
                ),
              ),
              Positioned(
                bottom: 250,
                right: 50,
                child: _buildDecorativeIcon(
                  Icons.emoji_events,
                  size: 28,
                  color: Colors.amber.withOpacity(0.25),
                ),
              ),
              
              // Decorative medals/badges
              Positioned(
                top: 200,
                left: 70,
                child: _buildDecorativeIcon(
                  Icons.military_tech,
                  size: 32,
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              Positioned(
                bottom: 180,
                left: 100,
                child: _buildDecorativeIcon(
                  Icons.military_tech,
                  size: 24,
                  color: Colors.blue.withOpacity(0.25),
                ),
              ),
              
              // Main content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo and app name with enhanced styling
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.sports_soccer,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Copenhagen Academy',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Text(
                          'Bliv stjernen på holdet!',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                      
                      // Login button with enhanced styling
                      _buildButton(
                        'LOG IND',
                        Colors.white,
                        const Color(0xFF3D007A),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Register button with enhanced styling
                      _buildButton(
                        'OPRET BRUGER',
                        Colors.white,
                        Colors.transparent,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                        isOutlined: true,
                      ),
                      const SizedBox(height: 20),
                      
                      // About Academy button with enhanced styling
                      _buildButton(
                        'HVEM ER VI?',
                        Colors.white,
                        Colors.transparent,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const InfoPage(),
                            ),
                          );
                        },
                        isOutlined: true,
                      ),
                      const SizedBox(height: 40),
                      
                      // Terms and privacy text with enhanced styling
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 3,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Text(
                          'Ved at fortsætte accepterer du vores servicevilkår og privatlivspolitik',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            letterSpacing: 0.5,
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
      ),
    );
  }
  
  Widget _buildDecorativeIcon(IconData icon, {double size = 24, Color? color}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.05),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: size,
        color: color ?? Colors.white.withOpacity(0.2),
      ),
    );
  }
  
  Widget _buildButton(String text, Color textColor, Color backgroundColor, VoidCallback onPressed, {bool isOutlined = false}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: textColor,
                backgroundColor: backgroundColor,
                side: BorderSide(color: textColor, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                foregroundColor: textColor,
                elevation: 3,
                shadowColor: Colors.black.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 