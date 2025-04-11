import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/navigation_drawer.dart';

class SessionDetailsPage extends StatelessWidget {
  final String sessionTitle;

  const SessionDetailsPage({
    Key? key,
    this.sessionTitle = "Training Session",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          sessionTitle,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0B0057),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GradientBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.construction,
                  size: 80,
                  color: Colors.amber[300],
                ),
                const SizedBox(height: 24),
                const Text(
                  'KOMMER SNART!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Træningssessioner er under udvikling og vil være tilgængelige i den næste opdatering.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32, 
                      vertical: 16
                    ),
                  ),
                  child: const Text('Tilbage'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 