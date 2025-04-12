import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A service for managing profile images
class ProfileImageService {
  static const String _profileImageKey = 'profile_image_url';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isInitialized = false;
  String? _currentProfileImage;

  /// Initialize the service by loading any existing profile image
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _currentProfileImage = await _secureStorage.read(key: _profileImageKey);
      _isInitialized = true;
    } catch (e) {
      print('Error initializing ProfileImageService: $e');
      _isInitialized = false;
    }
  }

  /// Get the current profile image URL
  String? getCurrentProfileImage() {
    return _currentProfileImage;
  }

  /// Save a new profile image URL
  Future<void> saveProfileImage(String imageUrl) async {
    try {
      await _secureStorage.write(key: _profileImageKey, value: imageUrl);
      _currentProfileImage = imageUrl;
    } catch (e) {
      print('Error saving profile image: $e');
    }
  }

  /// Clear the saved profile image
  Future<void> clearProfileImage() async {
    try {
      await _secureStorage.delete(key: _profileImageKey);
      _currentProfileImage = null;
    } catch (e) {
      print('Error clearing profile image: $e');
    }
  }
} 