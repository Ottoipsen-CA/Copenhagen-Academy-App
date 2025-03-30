import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/player_test.dart';
import '../../services/player_tests_service.dart';
import '../../widgets/loading_indicator.dart';
import 'test_input_screen.dart';

class TestHistoryScreen extends StatefulWidget {
  const TestHistoryScreen({Key? key}) : super(key: key);

  @override
  _TestHistoryScreenState createState() => _TestHistoryScreenState();
}

class _TestHistoryScreenState extends State<TestHistoryScreen> {
  List<PlayerTest> _tests = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadTests();
  }
  
  Future<void> _loadTests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final tests = await PlayerTestsService.getPlayerTests();
      setState(() {
        _tests = tests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load test history: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test History'),
        backgroundColor: const Color(0xFF0B0057),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add New Test',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TestInputScreen(),
                ),
              ).then((_) => _loadTests());
            },
          ),
        ],
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
        child: _isLoading
            ? const LoadingIndicator(message: 'Loading test history...')
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadTests,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _tests.isEmpty
                    ? _buildEmptyState()
                    : _buildTestsList(),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center,
              color: Colors.white.withOpacity(0.5),
              size: 64,
            ),
            const SizedBox(height: 24),
            const Text(
              'No test history found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete physical tests to track your progress and improve your ratings.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TestInputScreen(),
                  ),
                ).then((_) => _loadTests());
              },
              icon: const Icon(Icons.add),
              label: const Text('RECORD YOUR FIRST TEST'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF02D39A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTestsList() {
    return RefreshIndicator(
      onRefresh: _loadTests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tests.length,
        itemBuilder: (context, index) {
          final test = _tests[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: Colors.white.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                'Test - ${DateFormat.yMMMd().format(test.testDate ?? DateTime.now())}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Overall Rating: ${_calculateOverall(test)}',
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF02D39A).withOpacity(0.2),
                child: const Icon(
                  Icons.sports_soccer,
                  color: Color(0xFF02D39A),
                ),
              ),
              iconColor: Colors.white,
              collapsedIconColor: Colors.white70,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 8),
                      const Text(
                        'Test Results:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTestResultRow('Passing', test.passingTest, test.passingRating),
                      _buildTestResultRow('Sprint', test.sprintTest, test.paceRating, isLowerBetter: true),
                      _buildTestResultRow('First Touch', test.firstTouchTest, test.firstTouchRating),
                      _buildTestResultRow('Shooting', test.shootingTest, test.shootingRating),
                      _buildTestResultRow('Juggling', test.jugglingTest, test.jugglingRating),
                      _buildTestResultRow('Dribbling', test.dribblingTest, test.dribblingRating, isLowerBetter: true),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildTestResultRow(String label, dynamic value, int? rating, {bool isLowerBetter = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value != null ? value.toString() + (isLowerBetter ? ' sec' : '') : 'N/A',
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getRatingColor(rating),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              rating != null ? rating.toString() : 'N/A',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  int _calculateOverall(PlayerTest test) {
    final ratings = [
      test.paceRating,
      test.shootingRating,
      test.passingRating,
      test.dribblingRating,
      test.jugglingRating,
      test.firstTouchRating,
    ].where((r) => r != null).map((r) => r!).toList();
    
    if (ratings.isEmpty) return 0;
    
    return ratings.reduce((a, b) => a + b) ~/ ratings.length;
  }
  
  Color _getRatingColor(int? rating) {
    if (rating == null) return Colors.grey;
    if (rating >= 90) return Colors.green;
    if (rating >= 80) return Colors.lightGreen;
    if (rating >= 70) return Colors.amber;
    if (rating >= 60) return Colors.orange;
    return Colors.red;
  }
} 