import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/auth.dart';
import '../../services/auth_service.dart';
import '../../theme/colors.dart';
import '../dashboard/dashboard_page.dart';
import 'register_page.dart';
import '../../services/challenge_service.dart';
import '../info/info_page.dart';
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/profile_image_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _profileImageUrl;
  final ProfileImageService _profileImageService = ProfileImageService();

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    await _profileImageService.initialize();
    setState(() {
      _profileImageUrl = _profileImageService.getCurrentProfileImage();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
    if (kIsWeb) {
      // Create a file input element
      final input = html.FileUploadInputElement()..accept = 'image/*';
      input.click();

      await input.onChange.first;
      if (input.files!.isNotEmpty) {
        final file = input.files![0];
        final reader = html.FileReader();
        
        reader.readAsDataUrl(file);
        await reader.onLoad.first;
        
        final imageData = reader.result as String;
        
        // Save the image to the profile service
        await _profileImageService.saveProfileImage(imageData);
        
        setState(() {
          _profileImageUrl = imageData;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF280070), // Dark purple
              Color(0xFF3D0099), // Mid purple
              Color(0xFF8800BB), // Pink/purple
              Color(0xFFFF3399), // Pink
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > 600;
            
            if (isLandscape) {
              return _buildLandscapeLayout();
            } else {
              return _buildPortraitLayout();
            }
          },
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
                      _buildMissionText(),
                      const SizedBox(height: 30),
                      _buildLoginForm(),
                      const SizedBox(height: 20),
                      _buildSignUpSection(),
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
  
  Widget _buildPortraitLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildAppHeader(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Center(
                  child: SizedBox(
                    width: 220,
                    child: _buildPlayerCard(),
                  ),
                ),
                const SizedBox(height: 20),
                _buildMissionText(),
                const SizedBox(height: 20),
                _buildLoginForm(),
                const SizedBox(height: 20),
                _buildSignUpSection(),
                const SizedBox(height: 20),
                // Add Learn More button
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/info');
                  },
                  icon: const Icon(
                    Icons.info_outline,
                    color: Colors.white70,
                  ),
                  label: const Text(
                    'Læa mere om Copenhagen Academy',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Colors.white.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
              Icon(Icons.emoji_events, color: Colors.amber[300], size: 24),
              const SizedBox(width: 10),
              Text(
                "COPENHAGEN ACADEMY",
                style: TextStyle(
                  color: Colors.amber[300],
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.emoji_events, color: Colors.amber[300], size: 24),
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700), // Gold color
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.amber[300]!,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top part of card with player rating and picture
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700), // Gold color
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Left side: Rating number and position
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E22AA), // Dark blue
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.amber[300]!,
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "94",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "PAC",
                      style: TextStyle(
                        color: Color(0xFF1E22AA),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E22AA),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.amber[300]!,
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        "ST",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Player icon/avatar
                Expanded(
                  child: Container(
                    height: 140,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A3BAA),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.amber[300]!,
                                width: 2,
                              ),
                              image: _profileImageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(_profileImageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _profileImageUrl == null
                                ? const ClipOval(
                                    child: Icon(
                                      Icons.sports_soccer,
                                      color: Colors.white,
                                      size: 50,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        // Camera icon overlay
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.amber[700],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                        // Badge positioned at the bottom right
                        Positioned(
                          bottom: 5,
                          right: 25,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.local_fire_department,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        // Trophy badge at top left
                        Positioned(
                          top: 5,
                          left: 25,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.amber[700],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.emoji_events,
                              color: Colors.white,
                              size: 16,
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
          
          // PLAYER text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber[700]!,
                  Colors.amber[300]!,
                  Colors.amber[700]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Text(
              "Christian",
              style: TextStyle(
                color: Color(0xFF1E22AA),
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Player stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStat("97", "PAC"),
                    _buildStat("92", "DRI"),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStat("90", "SHO"),
                    _buildStat("39", "DEF"),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStat("80", "PAS"),
                    _buildStat("78", "PHY"),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
  
  Widget _buildStat(String value, String label) {
    return Row(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1E22AA),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1E22AA),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMissionText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Træn",
              style: TextStyle(
                color: Colors.yellow,
                fontSize: 46,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.sports_soccer, color: Colors.amber[300], size: 30),
          ],
        ),
        Row(
          children: [
            const Text(
              "og bliv stjernen på holdet!",
              style: TextStyle(
                color: Colors.yellow,
                fontSize: 46,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.emoji_events, color: Colors.amber[300], size: 30),
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
          
          // Error message
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
            height: 60,
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
                        fontSize: 24,
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
    return Column(
      children: [
        Text(
          "Har du ikke en bruger?",
          style: TextStyle(
            color: Colors.yellow.shade200,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.yellow,
              width: 3,
            ),
          ),
          child: TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const RegisterPage(),
                ),
              );
            },
            child: const Text(
              'OPRET BRUGER',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.yellow,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // About Academy button
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InfoPage(),
                ),
              );
            },
            child: const Text(
              'Hvem er vi?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
} 