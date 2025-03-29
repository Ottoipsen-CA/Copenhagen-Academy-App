import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../models/challenge.dart';
import '../../services/challenge_progress_service.dart';

class ChallengeCompletionPage extends StatefulWidget {
  final int challengeId;
  final String challengeName;
  final String challengeCategory;

  const ChallengeCompletionPage({
    Key? key,
    required this.challengeId,
    required this.challengeName,
    required this.challengeCategory,
  }) : super(key: key);

  @override
  State<ChallengeCompletionPage> createState() => _ChallengeCompletionPageState();
}

class _ChallengeCompletionPageState extends State<ChallengeCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  final _scoreController = TextEditingController();
  final _minutesController = TextEditingController();
  final _secondsController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isSubmitting = false;

  @override
  void dispose() {
    _scoreController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitCompletion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Calculate total seconds
      final minutes = int.tryParse(_minutesController.text) ?? 0;
      final seconds = int.tryParse(_secondsController.text) ?? 0;
      final totalSeconds = (minutes * 60) + seconds;
      
      // Get score
      final score = double.tryParse(_scoreController.text) ?? 0.0;
      
      // Create stats object
      final stats = {
        'notes': _notesController.text,
        'completion_date': DateTime.now().toIso8601String(),
        'category': widget.challengeCategory,
      };
      
      final service = Provider.of<ChallengeProgressService>(context, listen: false);
      
      await service.completeChallenge(
        challengeId: widget.challengeId,
        completionTime: totalSeconds,
        score: score,
        stats: stats,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Challenge completed! You earned a badge!')),
        );
        
        // Return to previous screen after short delay
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context, true); // Return true to indicate success
        });
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Challenge'),
        backgroundColor: _getCategoryColor(widget.challengeCategory),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.challengeName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Category: ${widget.challengeCategory}',
                style: TextStyle(
                  fontSize: 16,
                  color: _getCategoryColor(widget.challengeCategory),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Record your performance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              
              // Score
              TextFormField(
                controller: _scoreController,
                decoration: const InputDecoration(
                  labelText: 'Score',
                  hintText: 'Enter your score (0-100)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a score';
                  }
                  final score = double.tryParse(value);
                  if (score == null) {
                    return 'Please enter a valid number';
                  }
                  if (score < 0 || score > 100) {
                    return 'Score must be between 0 and 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Completion time
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minutesController,
                      decoration: const InputDecoration(
                        labelText: 'Minutes',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final minutes = int.tryParse(value);
                        if (minutes == null || minutes < 0) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _secondsController,
                      decoration: const InputDecoration(
                        labelText: 'Seconds',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final seconds = int.tryParse(value);
                        if (seconds == null || seconds < 0 || seconds > 59) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Any comments about your performance',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              
              const SizedBox(height: 24),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitCompletion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getCategoryColor(widget.challengeCategory),
                    foregroundColor: Colors.white,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('COMPLETE CHALLENGE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'passing':
        return Colors.blue;
      case 'shooting':
        return Colors.red;
      case 'dribbling':
        return Colors.green;
      case 'fitness':
        return Colors.orange;
      case 'defense':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }
} 