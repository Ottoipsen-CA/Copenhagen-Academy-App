import 'package:flutter/material.dart';
import '../screens/auth/login_page.dart';

// GlobalKey to access navigator from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NavigationService {
  // Get the navigator state using the global key
  static NavigatorState? get navigator => navigatorKey.currentState;

  // Navigate to login page and clear all previous routes
  static void resetToLogin() {
    if (navigator != null) {
      // First close any open dialogs or drawers
      navigator!.popUntil((route) => route.isFirst);
      
      // Then replace everything with the login page
      navigator!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()), 
        (route) => false
      );
    }
  }
} 