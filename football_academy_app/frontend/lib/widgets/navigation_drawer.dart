import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/dashboard/dashboard_page.dart';
import '../screens/auth/landing_page.dart';
import '../screens/training/training_plans_page.dart';
import '../screens/exercises/exercises_page.dart';

class CustomNavigationDrawer extends StatelessWidget {
  final String currentPage;

  const CustomNavigationDrawer({
    super.key,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  context,
                  'dashboard',
                  'Dashboard',
                  Icons.dashboard_outlined,
                  () => _navigateTo(context, 'dashboard'),
                ),
                _buildNavItem(
                  context,
                  'training',
                  'Training Plan',
                  Icons.fitness_center,
                  () => _navigateTo(context, 'training'),
                ),
                _buildNavItem(
                  context,
                  'exercises',
                  'Exercise Library',
                  Icons.video_library_outlined,
                  () => _navigateTo(context, 'exercises'),
                ),
                _buildNavItem(
                  context,
                  'achievements',
                  'Achievements',
                  Icons.emoji_events_outlined,
                  () => _navigateTo(context, 'achievements'),
                ),
                _buildNavItem(
                  context,
                  'chat',
                  'Chat with Coach',
                  Icons.chat_outlined,
                  () => _navigateTo(context, 'chat'),
                ),
                const Divider(),
                _buildNavItem(
                  context,
                  'profile',
                  'My Profile',
                  Icons.person_outline,
                  () => _navigateTo(context, 'profile'),
                ),
                _buildNavItem(
                  context,
                  'settings',
                  'Settings',
                  Icons.settings_outlined,
                  () => _navigateTo(context, 'settings'),
                ),
              ],
            ),
          ),
          const Divider(),
          _buildLogoutButton(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLogo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size * 0.4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(size * 0.5),
                  topRight: Radius.circular(size * 0.5),
                ),
              ),
            ),
          ),
          
          Positioned(
            bottom: size * 0.1,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: size * 0.01),
                  child: Icon(
                    Icons.star,
                    color: Colors.white,
                    size: size * 0.1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0B0057), // Dark blue/purple
            Color(0xFF1C006C), // Mid purple
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildLogo(70),
          const SizedBox(height: 12),
          const Text(
            'COPENHAGEN ACADEMY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Develop your football skills',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String id,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    final isSelected = currentPage == id;
    final color = isSelected ? Theme.of(context).primaryColor : Colors.grey.shade700;
    
    return ListTile(
      leading: Icon(
        icon,
        color: color,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: 
          Theme.of(context).primaryColor.withOpacity(0.1),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.exit_to_app,
        color: Colors.red,
      ),
      title: const Text(
        'Logout',
        style: TextStyle(
          color: Colors.red,
        ),
      ),
      onTap: () async {
        // Close drawer
        Navigator.pop(context);
        
        // Show confirmation dialog
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('LOGOUT'),
              ),
            ],
          ),
        );
        
        if (confirm == true) {
          // Logout
          final authService = Provider.of<AuthService>(context, listen: false);
          await authService.logout();
          
          // Navigate to landing page
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LandingPage()),
              (route) => false,
            );
          }
        }
      },
    );
  }

  void _navigateTo(BuildContext context, String routeName) {
    // Close the drawer
    Navigator.pop(context);
    
    // If not already on the page, navigate to it
    if (currentPage != routeName) {
      switch (routeName) {
        case 'dashboard':
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => const DashboardPage())
          );
          break;
        case 'exercises':
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => const ExercisesPage())
          );
          break;
        case 'training':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TrainingPlansPage(),
            ),
          );
          break;
        default:
          // For pages without dedicated screens yet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$routeName page is coming soon!'),
              duration: const Duration(seconds: 2),
            ),
          );
      }
    }
  }
} 