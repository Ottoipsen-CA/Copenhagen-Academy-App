import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Football Academy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildFeatureCard(
              context,
              'Exercises',
              Icons.fitness_center,
              Colors.blue,
              () {
                Navigator.pushNamed(context, '/exercises');
              },
            ),
            _buildFeatureCard(
              context,
              'Challenges',
              Icons.emoji_events,
              Colors.orange,
              () {
                Navigator.pushNamed(context, '/challenges');
              },
            ),
            _buildFeatureCard(
              context,
              'League Table',
              Icons.leaderboard,
              Colors.green,
              () {
                Navigator.pushNamed(context, '/league_table');
              },
            ),
            _buildFeatureCard(
              context,
              'Training Schedule',
              Icons.calendar_today,
              Colors.purple,
              () {
                Navigator.pushNamed(context, '/training_schedule');
              },
            ),
            _buildFeatureCard(
              context,
              'Test API',
              Icons.bug_report,
              Colors.red,
              () {
                Navigator.pushNamed(context, '/test');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 