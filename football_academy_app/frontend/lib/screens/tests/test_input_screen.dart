import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/player_test.dart';
import '../../services/player_tests_service.dart';
import '../../widgets/loading_indicator.dart';

class TestInputScreen extends StatefulWidget {
  const TestInputScreen({Key? key}) : super(key: key);

  @override
  _TestInputScreenState createState() => _TestInputScreenState();
}

class _TestInputScreenState extends State<TestInputScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  
  // Test result controllers
  final _passingTestController = TextEditingController();
  final _sprintTestController = TextEditingController();
  final _firstTouchTestController = TextEditingController();
  final _shootingTestController = TextEditingController();
  final _jugglingTestController = TextEditingController();
  final _dribblingTestController = TextEditingController();
  
  // Test descriptions for help tooltip
  final Map<String, String> _testDescriptions = {
    'passing': 'Number of successful passes in 1 minute',
    'sprint': 'Time in seconds for 15m sprint (lower is better)',
    'firstTouch': 'Number of successful first touches in 1 minute',
    'shooting': 'Number of successful goals out of 15 shots',
    'juggling': 'Number of juggles in 1 minute',
    'dribbling': 'Time in seconds for dribbling course (lower is better)',
  };

  @override
  void dispose() {
    _passingTestController.dispose();
    _sprintTestController.dispose();
    _firstTouchTestController.dispose();
    _shootingTestController.dispose();
    _jugglingTestController.dispose();
    _dribblingTestController.dispose();
    super.dispose();
  }

  Future<void> _submitTestResults() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Create test object
      final test = PlayerTest(
        passingTest: int.tryParse(_passingTestController.text),
        sprintTest: double.tryParse(_sprintTestController.text),
        firstTouchTest: int.tryParse(_firstTouchTestController.text),
        shootingTest: int.tryParse(_shootingTestController.text),
        jugglingTest: int.tryParse(_jugglingTestController.text),
        dribblingTest: double.tryParse(_dribblingTestController.text),
      );
      
      print('Submitting test results: ${test.toJson()}');
      
      // Submit test results to backend
      final result = await PlayerTestsService.submitTestResults(test);
      
      // Show success dialog with ratings
      if (mounted) {
        _showSuccessDialog(result);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to submit test results: ${e.toString()}';
      });
      print('Error submitting test results: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _showSuccessDialog(PlayerTest result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Test Results Submitted'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your test has been submitted successfully!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('Calculated Ratings:'),
                const SizedBox(height: 8),
                _buildRatingRow('Pace', result.paceRating),
                _buildRatingRow('Shooting', result.shootingRating),
                _buildRatingRow('Passing', result.passingRating),
                _buildRatingRow('Dribbling', result.dribblingRating),
                _buildRatingRow('Juggling', result.jugglingRating),
                _buildRatingRow('First Touch', result.firstTouchRating),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true); // Return to previous screen
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildRatingRow(String label, int? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getRatingColor(value),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${value ?? 'N/A'}',
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
  
  Color _getRatingColor(int? rating) {
    if (rating == null) return Colors.grey;
    if (rating >= 90) return Colors.green;
    if (rating >= 80) return Colors.lightGreen;
    if (rating >= 70) return Colors.amber;
    if (rating >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Test Results'),
        backgroundColor: const Color(0xFF0B0057),
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
            ? const LoadingIndicator(message: 'Submitting test results...')
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Record Your Physical Tests',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter your test results from your latest training session. These will be used to calculate your skill ratings.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Passing Test
                      _buildTestInput(
                        'Passing Test',
                        _passingTestController,
                        _testDescriptions['passing']!,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) => _validateIntInput(value, 'passing test'),
                      ),
                      const SizedBox(height: 16),
                      
                      // Sprint Test
                      _buildTestInput(
                        'Sprint Test (seconds)',
                        _sprintTestController,
                        _testDescriptions['sprint']!,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        validator: (value) => _validateDoubleInput(value, 'sprint test', minValue: 1.0, maxValue: 10.0),
                      ),
                      const SizedBox(height: 16),
                      
                      // First Touch Test
                      _buildTestInput(
                        'First Touch Test',
                        _firstTouchTestController,
                        _testDescriptions['firstTouch']!,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) => _validateIntInput(value, 'first touch test'),
                      ),
                      const SizedBox(height: 16),
                      
                      // Shooting Test
                      _buildTestInput(
                        'Shooting Test',
                        _shootingTestController,
                        _testDescriptions['shooting']!,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) => _validateIntInput(value, 'shooting test', maxValue: 15),
                      ),
                      const SizedBox(height: 16),
                      
                      // Juggling Test
                      _buildTestInput(
                        'Juggling Test',
                        _jugglingTestController,
                        _testDescriptions['juggling']!,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) => _validateIntInput(value, 'juggling test'),
                      ),
                      const SizedBox(height: 16),
                      
                      // Dribbling Test
                      _buildTestInput(
                        'Dribbling Test (seconds)',
                        _dribblingTestController,
                        _testDescriptions['dribbling']!,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        validator: (value) => _validateDoubleInput(value, 'dribbling test', minValue: 5.0, maxValue: 60.0),
                      ),
                      const SizedBox(height: 32),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitTestResults,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'SUBMIT TEST RESULTS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
  
  Widget _buildTestInput(
    String label,
    TextEditingController controller,
    String description, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: description,
              child: const Icon(
                Icons.info_outline,
                color: Colors.white54,
                size: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            hintText: 'Enter value',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          ),
        ),
      ],
    );
  }
  
  String? _validateIntInput(String? value, String field, {int? minValue, int? maxValue}) {
    if (value == null || value.isEmpty) {
      return null; // Optional fields are allowed
    }
    
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Please enter a valid number';
    }
    
    if (minValue != null && intValue < minValue) {
      return '$field should be at least $minValue';
    }
    
    if (maxValue != null && intValue > maxValue) {
      return '$field should be at most $maxValue';
    }
    
    return null;
  }
  
  String? _validateDoubleInput(String? value, String field, {double? minValue, double? maxValue}) {
    if (value == null || value.isEmpty) {
      return null; // Optional fields are allowed
    }
    
    final doubleValue = double.tryParse(value);
    if (doubleValue == null) {
      return 'Please enter a valid number';
    }
    
    if (minValue != null && doubleValue < minValue) {
      return '$field should be at least ${minValue.toStringAsFixed(1)}';
    }
    
    if (maxValue != null && doubleValue > maxValue) {
      return '$field should be at most ${maxValue.toStringAsFixed(1)}';
    }
    
    return null;
  }
} 