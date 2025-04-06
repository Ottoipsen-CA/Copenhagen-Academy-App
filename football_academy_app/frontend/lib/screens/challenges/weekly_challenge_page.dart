import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/challenge.dart';
import '../../services/auth_service.dart';
import '../../services/challenge_service.dart';
import 'challenge_leaderboard_page.dart';

class WeeklyChallengePage extends StatefulWidget {
  final Challenge challenge;

  const WeeklyChallengePage({Key? key, required this.challenge}) : super(key: key);

  @override
  State<WeeklyChallengePage> createState() => _WeeklyChallengePageState();
}

class _WeeklyChallengePageState extends State<WeeklyChallengePage> {
  late GlobalKey<FormState> _formKey;
  late TextEditingController _valueController;
  bool _isSubmitting = false;
  Challenge? _updatedChallenge;
  
  Challenge get challenge => _updatedChallenge ?? widget.challenge;
  
  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _valueController = TextEditingController();
    
    // Pre-fill with current record if exists
    if (challenge.userSubmission != null) {
      _valueController.text = challenge.userSubmission!.value.toString();
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _submitResult() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    final value = double.parse(_valueController.text);
    
    try {
      final success = await ChallengeService.submitChallengeResult(
        challenge.id,
        value,
      );
      
      if (success) {
        // Reload challenge to get updated status
        final updatedChallenge = await ChallengeService.getChallengeById(challenge.id);
        
        setState(() {
          if (updatedChallenge != null) {
            _updatedChallenge = updatedChallenge;
          }
          _isSubmitting = false;
          _showSnackBar('Result submitted successfully!', isError: false);
        });
      } else {
        setState(() {
          _isSubmitting = false;
          _showSnackBar('Failed to submit result. Please try again.');
        });
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _showSnackBar('Error: ${e.toString()}');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Challenge'),
        backgroundColor: const Color(0xFF0B0057),
        actions: [
          // Leaderboard button
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChallengeLeaderboardPage(
                    challenge: challenge,
                  ),
                ),
              );
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero image if available
              if (challenge.imageUrl != null)
                Image.network(
                  challenge.imageUrl!,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Challenge title
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Challenge description
                    Text(
                      challenge.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Time remaining
                    _buildTimeRemaining(),
                    
                    const SizedBox(height: 24),
                    
                    // Participants info
                    _buildParticipantsInfo(),
                    
                    const SizedBox(height: 24),
                    
                    // Current submission or submission form
                    challenge.userSubmission != null
                        ? _buildCurrentSubmission()
                        : _buildSubmissionForm(),
                    
                    const SizedBox(height: 32),
                    
                    // Leaderboard section
                    _buildLeaderboardSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentSubmission() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 10),
              const Text(
                'YOUR SUBMISSION',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                'Rank: #${challenge.userSubmission!.rank}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Record',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    challenge.formatMetric(challenge.userSubmission!.value),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Submitted on',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(challenge.userSubmission!.submittedAt),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (challenge.isActive) 
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _valueController.text = challenge.userSubmission!.value.toString();
                  });
                  // Show form to update submission
                  _showUpdateDialog();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Update Submission'),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildSubmissionForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Submit Your Record',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Record your achievement',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _valueController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Your Record',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFFA500)),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              suffixText: 'Count',
              suffixStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your record';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitResult,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA500),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Submit Record',
                    ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLeaderboardSection() {
    if (challenge.leaderboard.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Leaderboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        // Header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const SizedBox(width: 30), // Space for rank
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Player',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Score',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Leaderboard entries
        ...challenge.leaderboard.map((submission) {
          final isUser = challenge.userSubmission != null && 
                        submission.userId == challenge.userSubmission!.userId;
                        
          final rankColors = {
            1: const Color(0xFFFFD700), // Gold
            2: const Color(0xFFC0C0C0), // Silver
            3: const Color(0xFFCD7F32), // Bronze
          };
          
          final rankColor = rankColors[submission.rank] ?? Colors.white.withOpacity(0.7);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser ? Colors.green.withOpacity(0.1) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: isUser
                  ? Border.all(color: Colors.green.withOpacity(0.5))
                  : null,
            ),
            child: Row(
              children: [
                // Rank
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: rankColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: rankColor,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${submission.rank}',
                      style: TextStyle(
                        color: rankColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // User avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    image: submission.userImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(submission.userImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: submission.userImageUrl == null
                      ? Center(
                          child: Text(
                            submission.userName.substring(0, 1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                
                // Name
                Expanded(
                  child: Text(
                    submission.userName,
                    style: TextStyle(
                      color: isUser ? Colors.green : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                
                // Score
                Text(
                  '${submission.value}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTimeRemaining() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time,
            color: Colors.white70,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TIME REMAINING',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                challenge.isActive
                  ? challenge.timeRemaining
                  : 'Challenge ended',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.people,
            color: Colors.white70,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PARTICIPANTS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${challenge.participantCount} players competing',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: challenge.userSubmission == null
                ? () => _scrollToSubmissionForm()
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA500),
              disabledBackgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              challenge.userSubmission == null
                  ? 'JOIN'
                  : 'JOINED',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // Method to scroll to submission form
  void _scrollToSubmissionForm() {
    // Implementation would depend on using a ScrollController
    // For now, we'll just show a snack bar
    _showSnackBar('Scroll down to submit your record', isError: false);
  }

  // Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  // Show dialog to update submission
  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C006C),
        title: const Text(
          'Update Your Record',
          style: TextStyle(color: Colors.white),
        ),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'New Record',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white30),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFFA500)),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your record';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(context);
                _submitResult();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA500),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
} 