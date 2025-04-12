import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math; // Import math
import '../../models/auth.dart';
import '../../services/auth_service.dart';
import '../dashboard/dashboard_page.dart';
import 'login_page.dart';
import '../../theme/colors.dart'; // Import AppColors
import '../../widgets/decorative_backgrounds.dart'; // Import shared backgrounds

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _positionController = TextEditingController();
  final _clubController = TextEditingController();
  
  // Add position enum values
  final List<String> _positions = [
    'goalkeeper',
    'defender',
    'midfielder',
    'striker'
  ];
  String? _selectedPosition;
  
  DateTime? _selectedDate;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _positionController.dispose();
    _clubController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      print('Attempting to register with email: ${_emailController.text.trim()}');
      
      final registerRequest = RegisterRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        position: _selectedPosition,
        currentClub: _clubController.text.isEmpty ? null : _clubController.text.trim(),
        dateOfBirth: _selectedDate,
      );
      
      final user = await authService.register(registerRequest);
      print('Registration successful: ${user.email}');
      
      // Login after successful registration
      print('Attempting to login after registration');
      await authService.login(
        LoginRequest(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
      print('Login successful');
      
      if (!mounted) return;
      
      // Navigate to dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const DashboardPage(),
        ),
      );
    } catch (e) {
      print('Registration error: $e');
      setState(() {
        _errorMessage = 'Registration failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
              const BackgroundRadarGraphic(),
              const BottomPitchGraphic(),
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildAppHeader(),
                          const SizedBox(height: 30),
                          
                          const Text(
                            'Opret Bruger',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Bliv en del af Copenhagen Academy',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 30),
                          
                          // --- Styled Form Fields ---
                          _buildTextField(
                            controller: _fullNameController,
                            hintText: 'Fulde Navn',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Indtast venligst dit fulde navn';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _emailController,
                            hintText: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
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
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            hintText: 'Adgangskode',
                            icon: Icons.lock_outline,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Indtast din adgangskode';
                              }
                              if (value.length < 6) {
                                return 'Adgangskode skal være mindst 6 tegn';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            hintText: 'Bekræft Adgangskode',
                            icon: Icons.lock_outline,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Bekræft venligst din adgangskode';
                              }
                              if (value != _passwordController.text) {
                                return 'Adgangskoderne matcher ikke';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Replace position text field with dropdown
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedPosition,
                              decoration: InputDecoration(
                                hintText: 'Position (valgfrit)',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                ),
                                prefixIcon: Icon(Icons.sports_soccer_outlined, color: Colors.white.withOpacity(0.7)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                border: InputBorder.none,
                              ),
                              dropdownColor: const Color(0xFF0B0033),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                              ),
                              items: _positions.map((String position) {
                                return DropdownMenuItem<String>(
                                  value: position,
                                  child: Text(
                                    position[0].toUpperCase() + position.substring(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedPosition = newValue;
                                  _positionController.text = newValue ?? '';
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _clubController,
                            hintText: 'Nuværende Klub (valgfrit)',
                            icon: Icons.group_outlined,
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => _selectDate(context),
                            child: AbsorbPointer(
                              child: _buildTextField(
                                controller: TextEditingController(
                                  text: _selectedDate == null
                                      ? ''
                                      : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                                ),
                                hintText: 'Fødselsdato (valgfrit)',
                                icon: Icons.calendar_today_outlined,
                                readOnly: true,
                              ),
                            ),
                          ),
                          
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 14),
                              ),
                            ),
                          
                          const SizedBox(height: 24),
                          
                          // Styled Register Button
                          Container(
                            height: 56,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E22AA), Color(0xFF3F25BB)],
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
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
                                      'OPRET BRUGER',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // Styled Login option
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Har du allerede en bruger? ',
                                style: TextStyle(color: Colors.white.withOpacity(0.8)),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginPage()),
                                  );
                                },
                                child: Text(
                                  'Log ind',
                                  style: TextStyle(
                                    color: Colors.yellow[300],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for styled text fields (similar to LoginPage)
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1), // Semi-transparent white
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        readOnly: readOnly,
        style: const TextStyle(color: Colors.white), // White input text
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: InputBorder.none, // Remove default border
          errorStyle: const TextStyle(color: Colors.redAccent) // Error text style
        ),
        validator: validator,
      ),
    );
  }

 // Add App Header method (copied/adapted from LoginPage)
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

  // Add Badge Icon helper (copied/adapted from LoginPage)
  Widget _buildBadgeIcon(IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(icon, color: color, size: 16),
    );
  }
}

// TODO: Define or import BackgroundRadarGraphic and BottomPitchGraphic
// These widgets are currently defined in login_page.dart and need to be
// moved to a shared location (e.g., widgets/decorative/) or redefined here.

// Placeholder definitions to avoid immediate errors:
// class BackgroundRadarGraphic extends StatelessWidget {
//   const BackgroundRadarGraphic({Key? key}) : super(key: key);
//   @override Widget build(BuildContext context) => const SizedBox.shrink(); 
// }
// class BottomPitchGraphic extends StatelessWidget {
//   const BottomPitchGraphic({Key? key}) : super(key: key);
//   @override Widget build(BuildContext context) => const SizedBox.shrink(); 
// } 