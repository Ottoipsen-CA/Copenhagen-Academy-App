import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/player_test.dart';
import '../services/player_tests_service.dart';

class PlayerTestWidget extends StatefulWidget {
  const PlayerTestWidget({super.key});

  @override
  State<PlayerTestWidget> createState() => _PlayerTestWidgetState();
}

class _PlayerTestWidgetState extends State<PlayerTestWidget> {
  List<PlayerTest> _tests = [];
  bool _isLoading = true;
  bool _showForm = false;
  
  // Form controllers
  final TextEditingController _passingController = TextEditingController();
  final TextEditingController _sprintController = TextEditingController();
  final TextEditingController _firstTouchController = TextEditingController();
  final TextEditingController _shootingController = TextEditingController();
  final TextEditingController _jugglingController = TextEditingController();
  final TextEditingController _dribblingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize the PlayerTestsService
    PlayerTestsService.initialize(context);
    _loadTests();
  }
  
  @override
  void dispose() {
    _passingController.dispose();
    _sprintController.dispose();
    _firstTouchController.dispose();
    _shootingController.dispose();
    _jugglingController.dispose();
    _dribblingController.dispose();
    super.dispose();
  }
  
  Future<void> _loadTests() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final tests = await PlayerTestsService.getPlayerTests(context);
      setState(() {
        _tests = tests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fejl ved indlæsning af test: ${e.toString()}')),
      );
    }
  }
  
  // Add delete test function
  Future<void> _deleteTest(int? testId) async {
    if (testId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kan ikke slette test med ukendt ID')),
      );
      return;
    }
    
    // Show confirmation dialog
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text('Delete Test', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Er du sikker på, at du vil slette denne test? Denne handling kan ikke gendannes.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.2),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    try {
      final success = await PlayerTestsService.deletePlayerTest(context, testId);
      if (success) {
        // Remove test from list
        setState(() {
          _tests.removeWhere((test) => test.id == testId);
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test slettet succesfuldt')),
        );
      }
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fejl ved sletning af test: ${e.toString()}')),
      );
    }
  }
  
  Future<void> _submitTest() async {
    // Validate inputs
    if (_passingController.text.isEmpty ||
        _sprintController.text.isEmpty ||
        _firstTouchController.text.isEmpty ||
        _shootingController.text.isEmpty ||
        _jugglingController.text.isEmpty ||
        _dribblingController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indtast alle felter')),
      );
      return;
    }
    
    // Create test object
    final test = PlayerTest(
      testDate: DateTime.now(),
      position: 'Unknown', // This should be set from player profile in a real app
      
      // New raw test values
      pace: double.tryParse(_sprintController.text), // Sprint test becomes pace
      passing: double.tryParse(_passingController.text),
      shooting: double.tryParse(_shootingController.text),
      dribbling: double.tryParse(_dribblingController.text),
      juggles: double.tryParse(_jugglingController.text),
      firstTouch: double.tryParse(_firstTouchController.text),
      
      // Legacy values for backward compatibility
      passingTest: int.tryParse(_passingController.text),
      sprintTest: double.tryParse(_sprintController.text),
      firstTouchTest: int.tryParse(_firstTouchController.text),
      shootingTest: int.tryParse(_shootingController.text),
      jugglingTest: int.tryParse(_jugglingController.text),
      dribblingTest: double.tryParse(_dribblingController.text),
    );
    
    try {
      // Submit test
      final submittedTest = await PlayerTestsService.submitTestResults(context, test);
      
      // Add to list and close form
      setState(() {
        _tests.insert(0, submittedTest);
        _showForm = false;
      });
      
      // Clear form
      _passingController.clear();
      _sprintController.clear();
      _firstTouchController.clear();
      _shootingController.clear();
      _jugglingController.clear();
      _dribblingController.clear();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test indsendt succesfuldt!')),
      );
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fejl ved indsendelse af test: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.black.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and add button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Spillertest',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showForm = !_showForm;
                    });
                  },
                  icon: Icon(
                    _showForm ? Icons.close : Icons.add,
                    color: Colors.white,
                    size: 24,
                  ),
                  label: Text(
                    _showForm ? 'Annuller' : 'Ny test',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Show form or test history
            Expanded(
              child: _showForm
                  ? _buildTestForm()
                  : _buildTestHistory(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTestForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Passing Test ---
          const Text(
            'Afleveringer: Spil bolden mod en mur i 1 minut. Indtast hvor mange succesfulde afleveringer du har.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildTestField(
            label: 'Afleveringer',
            controller: _passingController,
            icon: Icons.sports_soccer,
            keyboardType: TextInputType.number,
            helperText: 'Antal på 1 min',
          ),
          const SizedBox(height: 16),
          
          // --- Sprint Test ---
          const Text(
            'Sprint: Løb 15 meter så hurtigt du kan. Indtast tiden i sekunder (f.eks. 2.5).',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildTestField(
            label: 'Sprint',
            controller: _sprintController,
            icon: Icons.timer,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            helperText: '15m tid i sek',
          ),
          const SizedBox(height: 16),
          
          // --- First Touch Test ---
          const Text(
            'Første berøring: spark bolden ind i en mur, tæm den og spark den tilbage i muren. Tæl antal succesfulde førsteberøringerpå 1 minut.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildTestField(
            label: 'Første berøring',
            controller: _firstTouchController,
            icon: Icons.sports_soccer,
            keyboardType: TextInputType.number,
            helperText: 'Antal på 1 min',
          ),
          const SizedBox(height: 16),
          
          // --- Shooting Test ---
          const Text(
            'Skud: Forsøg at score så mange mål ud af 10 forsøg.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildTestField(
            label: 'Skud',
            controller: _shootingController,
            icon: Icons.sports_soccer,
            keyboardType: TextInputType.number,
            helperText: 'Point (1-100)',
          ),
          const SizedBox(height: 16),
          
          // --- Juggling Test ---
          const Text(
            'Jonglering: Hold bolden i luften så længe som muligt. Indtast dit højeste antal jongleringer i træk.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildTestField(
            label: 'Jonglering',
            controller: _jugglingController,
            icon: Icons.flutter_dash,
            keyboardType: TextInputType.number,
            helperText: 'Antal',
          ),
          const SizedBox(height: 16),
          
          // --- Dribbling Test ---
          const Text(
            'Dribling: Dribl gennem en keglebane. Indtast tiden i sekunder.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildTestField(
            label: 'Dribling',
            controller: _dribblingController,
            icon: Icons.directions_run,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            helperText: 'Tid i sek',
          ),
          const SizedBox(height: 24),
          
          // Submit button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _submitTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Gem resultater',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTestField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required TextInputType keyboardType,
    String? helperText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white24,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(icon, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          // Input field
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                helperText: helperText,
                helperStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTestHistory() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    
    if (_tests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Ingen testresultater endnu. Tag din første test!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    // Show list of previous tests
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tidligere resultater',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _tests.length > 5 ? 5 : _tests.length,
          itemBuilder: (context, index) {
            final test = _tests[index];
            final dateFormat = DateFormat.yMMMd();
            final date = test.testDate != null 
                ? dateFormat.format(test.testDate!) 
                : 'Ukendt dato';
            
            // Check if this test broke any records
            final bool brokeRecord = test.isPassingRecord == true || 
                                    test.isSprintRecord == true || 
                                    test.isFirstTouchRecord == true || 
                                    test.isShootingRecord == true || 
                                    test.isJugglingRecord == true || 
                                    test.isDribblingRecord == true;
                
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: brokeRecord 
                ? const Color(0xFF025D7F).withOpacity(0.5)  // Special color for record breakers
                : Colors.black.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: brokeRecord 
                  ? const BorderSide(color: Color(0xFF03B0F1), width: 1.5)
                  : BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          date,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        
                        // Action buttons and badges in a row
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Delete button
                            IconButton(
                              onPressed: () => _deleteTest(test.id),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 18,
                              ),
                              tooltip: 'Slet test',
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                              splashRadius: 20,
                            ),
                            const SizedBox(width: 8),
                            
                            // Show overall rating if available
                            if (test.overallRating != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'OVR: ${test.overallRating}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            if (test.overallRating != null && brokeRecord)
                              const SizedBox(width: 8),
                            
                            // Show record breaker badge if applicable
                            if (brokeRecord)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF03B0F1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.emoji_events,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'RECORD BREAKER',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Show ratings as Wrap instead of the duplicate test results
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildRating('Pace', test.paceRating ?? 0),
                        _buildRating('Shooting', test.shootingRating ?? 0),
                        _buildRating('Passing', test.passingRating ?? 0),
                        _buildRating('Dribbling', test.dribblingRating ?? 0),
                        _buildRating('Juggles', test.jugglesRating ?? 0),
                        _buildRating('First Touch', test.firstTouchRating ?? 0),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildRating(String label, int rating) {
    Color ratingColor;
    if (rating >= 85) {
      ratingColor = Colors.green;
    } else if (rating >= 70) {
      ratingColor = Colors.lightGreen;
    } else if (rating >= 60) {
      ratingColor = Colors.amber;
    } else if (rating >= 40) {
      ratingColor = Colors.orange;
    } else {
      ratingColor = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: ratingColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ratingColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
          ),
          Text(
            rating.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: ratingColor,
            ),
          ),
        ],
      ),
    );
  }
} 