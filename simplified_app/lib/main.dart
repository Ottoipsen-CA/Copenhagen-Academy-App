import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Copenhagen Academy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B0057)),
        fontFamily: 'Roboto',
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final player = Player(
    name: 'John Smith',
    position: 'ST',
    club: 'Copenhagen Academy',
    stats: PlayerStats(
      pace: 78,
      shooting: 82,
      passing: 75,
      dribbling: 85,
      defense: 65,
      physical: 80,
      overallRating: 79,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF0B0057),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B0057), // Dark blue/purple
              Color(0xFF1C006C), // Mid purple
              Color(0xFF3D007A), // Lighter purple
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Player card
                  _buildPlayerCard(),
                  const SizedBox(width: 16),
                  // Welcome text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome Back,',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          player.name.split(' ').first,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.sports_score),
                          label: const Text('RECORD TESTS'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0B0057),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Stats Section
              Card(
                color: Colors.black.withOpacity(0.2),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Player Stats',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: Row(
                          children: [
                            // Radar Chart
                            Expanded(
                              child: _buildRadarChart(),
                            ),
                            // Stats Bars
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildStatBar('Pace', player.stats.pace),
                                  _buildStatBar('Shooting', player.stats.shooting),
                                  _buildStatBar('Passing', player.stats.passing),
                                  _buildStatBar('Dribbling', player.stats.dribbling),
                                  _buildStatBar('Defense', player.stats.defense),
                                  _buildStatBar('Physical', player.stats.physical),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Challenge Card
              Card(
                color: Colors.deepPurple.withOpacity(0.3),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.yellow,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Weekly Challenge',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Complete 100 wall passes in 5 minutes',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: 0.65,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade300),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '65/100 completed',
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard() {
    return Card(
      color: Colors.blue.shade800,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              player.stats.overallRating.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              player.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              player.position,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              player.club,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarChart() {
    final values = [
      player.stats.pace / 100,
      player.stats.shooting / 100,
      player.stats.passing / 100,
      player.stats.dribbling / 100,
      player.stats.defense / 100,
      player.stats.physical / 100,
    ];
    
    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            dataEntries: values.map((value) => RadarEntry(value: value)).toList(),
            fillColor: Colors.blue.withOpacity(0.2),
            borderColor: Colors.blue,
            borderWidth: 2,
          ),
        ],
        radarBorderData: const BorderSide(color: Colors.transparent),
        borderData: FlBorderData(show: false),
        radarShape: RadarShape.polygon,
        radarBackgroundColor: Colors.transparent,
        getTitle: (index, angle) {
          final titles = ['PACE', 'SHOOTING', 'PASSING', 'DRIBBLING', 'DEFENSE', 'PHYSICAL'];
          return RadarChartTitle(
            text: index < titles.length ? titles[index] : '',
            angle: angle,
          );
        },
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        titlePositionPercentageOffset: 0.2,
        tickCount: 4,
        ticksTextStyle: const TextStyle(
          color: Colors.white60,
          fontSize: 10,
        ),
        tickBorderData: const BorderSide(color: Colors.white30, width: 1),
        gridBorderData: const BorderSide(color: Colors.white30, width: 1),
      ),
    );
  }

  Widget _buildStatBar(String label, int value) {
    final color = _getStatColor(value);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              Text(
                value.toString(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value / 100,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Color _getStatColor(int value) {
    if (value >= 90) return Colors.green;
    if (value >= 80) return Colors.lightGreen;
    if (value >= 70) return Colors.amber;
    if (value >= 60) return Colors.orange;
    return Colors.red;
  }
}

class Player {
  final String name;
  final String position;
  final String club;
  final PlayerStats stats;

  Player({
    required this.name,
    required this.position,
    required this.club,
    required this.stats,
  });
}

class PlayerStats {
  final int pace;
  final int shooting;
  final int passing;
  final int dribbling;
  final int defense;
  final int physical;
  final int overallRating;

  PlayerStats({
    required this.pace,
    required this.shooting,
    required this.passing,
    required this.dribbling,
    required this.defense,
    required this.physical,
    required this.overallRating,
  });
} 