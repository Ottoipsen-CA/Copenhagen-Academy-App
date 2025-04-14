import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/dashboard/dashboard_page.dart';
import '../screens/info/info_page.dart';
import '../screens/auth/login_page.dart';
import '../config/feature_flags.dart';

class CustomNavigationDrawer extends StatelessWidget {
  final String currentPage;

  const CustomNavigationDrawer({
    Key? key,
    required this.currentPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF0B0057),
        child: Column(
          children: [
            _buildDrawerHeader(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  FutureBuilder<Widget>(
                    future: _buildNavItem(
                      context,
                      'dashboard',
                      'Dashboard',
                      Icons.dashboard_outlined,
                      () => _navigateTo(context, 'dashboard'),
                    ),
                    builder: (context, snapshot) => snapshot.data ?? const SizedBox.shrink(),
                  ),
                  FutureBuilder<Widget>(
                    future: _buildNavItem(
                      context,
                      'leagueTable',
                      'League Table',
                      Icons.leaderboard,
                      () => _navigateTo(context, 'leagueTable'),
                    ),
                    builder: (context, snapshot) => snapshot.data ?? const SizedBox.shrink(),
                  ),
                  FutureBuilder<Widget>(
                    future: _buildNavItem(
                      context,
                      'developmentPlan',
                      'Udviklingsplan',
                      Icons.track_changes,
                      () => _navigateTo(context, 'developmentPlan'),
                    ),
                    builder: (context, snapshot) => snapshot.data ?? const SizedBox.shrink(),
                  ),
                  FutureBuilder<Widget>(
                    future: _buildNavItem(
                      context,
                      'coachDashboard',
                      'Coach Dashboard',
                      Icons.sports_soccer,
                      () => _navigateTo(context, 'coachDashboard'),
                      requiresAuth: true,
                      requiresCoach: true,
                    ),
                    builder: (context, snapshot) => snapshot.data ?? const SizedBox.shrink(),
                  ),
                  const Divider(),
                  FutureBuilder<Widget>(
                    future: _buildNavItem(
                      context,
                      'profile',
                      'Min Profil',
                      Icons.person_outline,
                      () => _navigateTo(context, 'profile'),
                    ),
                    builder: (context, snapshot) => snapshot.data ?? const SizedBox.shrink(),
                  ),
                  FutureBuilder<Widget>(
                    future: _buildNavItem(
                      context,
                      'info',
                      'Hvem er vi?',
                      Icons.info_outline,
                      () => Navigator.pushNamed(context, '/info'),
                      requiresAuth: false,
                    ),
                    builder: (context, snapshot) => snapshot.data ?? const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const Divider(),
            _buildLogoutButton(context),
            const SizedBox(height: 16),
          ],
        ),
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
            'Copenhagen Academy',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Udvikle dine færdigheder',
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

  Future<Widget> _buildNavItem(
    BuildContext context,
    String route,
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool requiresAuth = true,
    bool requiresCoach = false,
  }) async {
    final isSelected = currentPage == route;
    
    // Check if user is a coach if required
    if (requiresCoach) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.getCurrentUser();
      if (user == null || !user.isCoach) {
        return const SizedBox.shrink(); // Hide the item if user is not a coach
      }
    }

    return ListTile(
      selected: isSelected,
      selectedTileColor: Colors.white.withOpacity(0.1),
      leading: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.white70,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontSize: 16,
        ),
      ),
      onTap: () async {
        if (requiresAuth) {
          final authService = Provider.of<AuthService>(context, listen: false);
          final isLoggedIn = await authService.isLoggedIn();
          if (!isLoggedIn) {
            Navigator.pushReplacementNamed(context, '/login');
            return;
          }
        }
        onTap();
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

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
        Navigator.pop(context);
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Log ud'),
            content: const Text('Er du sikker på du vil logge ud?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('ANNULLER'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('LOG UD'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await authService.logout();
        }
      },
    );
  }

  void _navigateTo(BuildContext context, String page) {
    Navigator.pop(context);
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute == '/$page') return;

    switch (page) {
      case 'dashboard':
        Navigator.pushNamed(context, '/dashboard');
        break;
      case 'leagueTable':
        Navigator.pushNamed(context, '/league-table');
        break;
      case 'developmentPlan':
        Navigator.pushNamed(context, '/development-plan');
        break;
      case 'profile':
        Navigator.pushNamed(context, '/profile');
        break;
      case 'info':
        Navigator.pushNamed(context, '/info');
        break;
      case 'coachDashboard':
        Navigator.pushNamed(context, '/coach-dashboard');
        break;
      default:
        print('Unknown page route: $page');
        break;
    }
  }
}
