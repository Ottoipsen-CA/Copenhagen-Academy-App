import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileImageService {
  static const String _profileImageKey = 'user_profile_image';
  
  // Singleton pattern
  static final ProfileImageService _instance = ProfileImageService._internal();
  factory ProfileImageService() => _instance;
  ProfileImageService._internal();
  
  // Stream controller for profile image changes
  final ValueNotifier<String?> profileImageNotifier = ValueNotifier<String?>(null);
  
  // Initialize the service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedImage = prefs.getString(_profileImageKey);
    if (savedImage != null) {
      profileImageNotifier.value = savedImage;
    }
  }
  
  // Save profile image
  Future<void> saveProfileImage(String imageData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImageKey, imageData);
    profileImageNotifier.value = imageData;
  }
  
  // Get current profile image
  String? getCurrentProfileImage() {
    return profileImageNotifier.value;
  }
  
  // Clear profile image
  Future<void> clearProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileImageKey);
    profileImageNotifier.value = null;
  }
} 