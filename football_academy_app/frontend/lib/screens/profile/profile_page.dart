import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../screens/auth/login_page.dart';
import '../../models/user.dart';
import '../../repositories/api_auth_repository.dart';
import '../../services/api_service.dart'; // Assuming ApiService is needed for repository instantiation
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Assuming storage is needed for repo
import '../../widgets/custom_app_bar.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/navigation_drawer.dart';
import '../../theme/colors.dart';
import 'package:http/http.dart' as http; // Added for http.Client
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:image_picker/image_picker.dart'; // Needed for ImageSource
import 'dart:io'; // Needed for File
import '../../utils/image_picker_helper.dart'; // Import ImagePickerHelper

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late ApiAuthRepository _authRepository;
  User? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;
  String? _profileImagePath; // Store local image path

  // Controllers for editable fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _clubController = TextEditingController();
  final _positionController = TextEditingController();

  // Add position enum values
  final List<String> _positions = [
    'goalkeeper',
    'defender',
    'midfielder',
    'striker'
  ];
  String? _selectedPosition;

  @override
  void initState() {
    super.initState();
    // Instantiate dependencies - Adjust as per your actual dependency injection setup
    final httpClient = http.Client(); // Create an http client
    const storage = FlutterSecureStorage(); // Use the same storage instance
    final apiService = ApiService(client: httpClient, secureStorage: storage); // Provide both client and storage
    _authRepository = ApiAuthRepository(apiService, storage);
    _loadUserData();
    _selectedPosition = _positionController.text.isNotEmpty ? _positionController.text : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _clubController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _currentUser = user;
          // Initialize controllers with user data
          _nameController.text = user.fullName ?? '';
          _emailController.text = user.email ?? '';
          _clubController.text = user.currentClub ?? ''; // Use currentClub
          _positionController.text = user.position ?? ''; // Assuming 'position' field exists
          _isLoading = false;
          _selectedPosition = user.position;
        });
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load user data.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isLoading = false;
        });
      }
      print('Error loading user data: $e');
    }
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) {
      return; // Don't proceed if form is invalid
    }
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true; // Show loading indicator during save
    });

    // Create updated User object
    // Note: Assumes User model has copyWith or similar, or we manually create it
    // Ensure we only send fields that the backend expects/allows updating
    final updatedUser = User(
      id: _currentUser!.id, // Keep the original ID
      email: _emailController.text,
      fullName: _nameController.text,
      currentClub: _clubController.text.isNotEmpty ? _clubController.text : null, // Use currentClub
      position: _selectedPosition,
      // Include other necessary fields from _currentUser, ensuring they are not null
      isActive: _currentUser!.isActive,
      isCoach: _currentUser!.isCoach, // Add isCoach
      isCaptain: _currentUser!.isCaptain, // Add isCaptain
      role: _currentUser!.role, // Add role
      dateOfBirth: _currentUser!.dateOfBirth, // Add dateOfBirth
      // createdAt and lastLogin are usually handled by the backend
    );


    try {
      final savedUser = await _authRepository.updateUser(updatedUser);
      if (savedUser != null && mounted) {
        setState(() {
          _currentUser = savedUser;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error saving user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  // Add image picking logic
  Future<void> _pickImage() async {
    final String? imagePath = await ImagePickerHelper.pickImage();
    if (imagePath != null && mounted) {
      setState(() {
        _profileImagePath = imagePath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomNavigationDrawer(currentPage: 'profile'),
      appBar: CustomAppBar(title: 'Min Profil'),
      body: GradientBackground(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _currentUser == null) { // Only show full page loader initially
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_errorMessage != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)),
      ));
    }
    if (_currentUser == null) {
      return const Center(child: Text('Brugerdata kunne ikke indlæses.', style: TextStyle(color: Colors.white)));
    }

    // Build the enhanced profile UI
    return _buildProfileContent();
  }

  Widget _buildProfileContent() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildProfileHeader(),
        const SizedBox(height: 24),
        _buildPersonalInfoCard(),
        const SizedBox(height: 24),
        _buildEditableInfoCard(),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _saveUserData,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
          ),
          child: _isLoading 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
              : const Text('Gem ændringer'), // Updated button text
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    String initials = _currentUser!.fullName.isNotEmpty 
        ? _currentUser!.fullName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '?';

    // Determine if we have a valid image path (assuming local path for now)
    bool hasImage = _profileImagePath != null && _profileImagePath!.isNotEmpty;
    ImageProvider? backgroundImage = hasImage ? FileImage(File(_profileImagePath!)) : null;

    return Row(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 40, // Slightly larger radius
              backgroundColor: AppColors.primary.withOpacity(0.8),
              backgroundImage: backgroundImage, // Use image if available
              child: !hasImage 
                  ? Text(initials, style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)) 
                  : null, // Don't show initials if image exists
            ),
            // Edit button
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[800], 
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5)
              ),
              margin: const EdgeInsets.all(2), // Offset slightly
              child: InkWell(
                onTap: _pickImage,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(5.0),
                  child: Icon(Icons.edit, size: 16, color: Colors.white),
                ),
              ),
            )
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Hej, ${_currentUser!.firstName}!', 
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard() {
    // Display read-only info like DOB, Role
    final dateFormat = DateFormat('dd MMMM yyyy'); // For formatting date

    return Card(
      color: AppColors.cardBackground.withOpacity(0.7),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            if (_currentUser!.dateOfBirth != null)
              _buildInfoRow(Icons.cake_outlined, 'Fødselsdag', dateFormat.format(_currentUser!.dateOfBirth!)),
            _buildInfoRow(Icons.shield_outlined, 'Rolle', _currentUser!.role.capitalize()),
            if (_currentUser!.isCaptain)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Chip(
                  label: const Text('Anfører'), 
                  backgroundColor: Colors.amber[700],
                  avatar: const Icon(Icons.star, color: Colors.white, size: 16),
                  labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableInfoCard() {
    // Card for the editable form fields
    return Card(
       color: AppColors.cardBackground.withOpacity(0.7),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rediger Profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              _buildTextField(_nameController, 'Fulde Navn', validator: (value) { // Updated label
                if (value == null || value.isEmpty) {
                  return 'Indtast venligst dit fulde navn'; // Updated message
                }
                return null;
              }),
              const SizedBox(height: 16),
              _buildTextField(_emailController, 'Email', keyboardType: TextInputType.emailAddress, validator: (value) { 
                if (value == null || !value.contains('@')) {
                  return 'Indtast venligst en gyldig email'; // Updated message
                }
                return null;
              }),
              const SizedBox(height: 16),
              _buildTextField(_clubController, 'Klub (Valgfrit)'), // Updated label
              const SizedBox(height: 16),
              // Replace position text field with dropdown
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedPosition,
                  decoration: InputDecoration(
                    labelText: 'Position (Valgfrit)',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  dropdownColor: AppColors.cardBackground.withOpacity(0.7),
                  style: const TextStyle(color: Colors.white),
                  items: _positions.map((String position) {
                    return DropdownMenuItem<String>(
                      value: position,
                      child: Text(
                        position[0].toUpperCase() + position.substring(1),
                        style: const TextStyle(color: Colors.white),
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
            ],
          ),
        ),
      ),
    );
  }

  // Helper to build info rows with icons
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 16),
          Text('$label:', style: const TextStyle(color: Colors.white70, fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}

extension StringExtension on String {
    String capitalize() {
      if (this.isEmpty) {
        return "";
      }
      return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
    }
} 