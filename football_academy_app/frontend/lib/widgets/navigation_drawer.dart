import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/dashboard/dashboard_page.dart';
import '../screens/auth/landing_page.dart';

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

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.sports_soccer,
              size: 40,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Football Academy',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
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

  void _navigateTo(BuildContext context, String page) {
    Navigator.pop(context); // Close the drawer
    
    // Check if we're already on the target page to avoid unnecessary navigation
    if (currentPage == page) return;
    
    switch (page) {
      case 'dashboard':
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 'training':
        Navigator.pushReplacementNamed(context, '/training');
        break;
      case 'exercises':
        Navigator.pushReplacementNamed(context, '/exercises');
        break;
      case 'achievements':
        Navigator.pushReplacementNamed(context, '/achievements');
        break;
      case 'chat':
        Navigator.pushReplacementNamed(context, '/chat');
        break;
      case 'profile':
        Navigator.pushReplacementNamed(context, '/profile');
        break;
      case 'settings':
        Navigator.pushReplacementNamed(context, '/settings');
        break;
    }
  }
} 