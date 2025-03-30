import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/challenge.dart';
import '../../services/challenge_service.dart';
import '../../services/player_stats_service.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/gradient_background.dart';

class ChallengeDetailPage extends StatefulWidget {
  final Challenge challenge;
  final UserChallenge userChallenge;
  
  const ChallengeDetailPage({
    Key? key,
    required this.challenge,
    required this.userChallenge,
  }) : super(key: key);

  @override
  _ChallengeDetailPageState createState() => _ChallengeDetailPageState();
}

class _ChallengeDetailPageState extends State<ChallengeDetailPage> {
  late Challenge _challenge;
  late UserChallenge _userChallenge;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _challenge = widget.challenge;
    _userChallenge = widget.userChallenge;
    
    // Start the challenge if it's available
    if (_userChallenge.status == ChallengeStatus.available) {
      _startChallenge();
    }
  }
  
  @override
  void dispose() {
    _noteController.dispose();
    _valueController.dispose();
    super.dispose();
  }
  
  Future<void> _startChallenge() async {
    try {
      final updatedUserChallenge = await ChallengeService.startChallenge(_challenge.id);
      setState(() {
        _userChallenge = updatedUserChallenge;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting challenge: $e')),
      );
    }
  }
  
  Future<void> _recordAttempt() async {
    // Validate input
    if (_valueController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a value')),
      );
      return;
    }
    
    final value = int.tryParse(_valueController.text);
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number')),
      );
      return;
    }
    
    try {
      final updatedUserChallenge = await ChallengeService.recordAttempt(
        _challenge.id,
        value,
        notes: _noteController.text.isNotEmpty ? _noteController.text : null,
      );
      
      setState(() {
        _userChallenge = updatedUserChallenge;
        _valueController.clear();
        _noteController.clear();
      });
      
      if (_userChallenge.status == ChallengeStatus.completed) {
        _showCompletionDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attempt recorded successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error recording attempt: $e')),
      );
    }
  }
  
  void _showCompletionDialog() async {
    // Try to get player stats
    String improvedStat = '';
    String performanceText = '';
    
    // Determine which stat improved based on challenge category
    switch (_challenge.category) {
      case ChallengeCategory.passing:
        improvedStat = 'Passing';
        break;
      case ChallengeCategory.shooting:
        improvedStat = 'Shooting';
        break;
      case ChallengeCategory.dribbling:
        improvedStat = 'Dribbling';
        break;
      case ChallengeCategory.fitness:
        improvedStat = 'Pace and Physical';
        break;
      case ChallengeCategory.defense:
        improvedStat = 'Defense';
        break;
      case ChallengeCategory.goalkeeping:
        improvedStat = 'Defense and Physical';
        break;
      case ChallengeCategory.tactical:
        improvedStat = 'Multiple stats';
        break;
      case ChallengeCategory.wallTouches:
        improvedStat = 'Wall Touches';
        break;
      default:
        improvedStat = 'Overall Rating';
        break;
    }
    
    // Calculate performance score for feedback message
    final double performanceScore = _userChallenge.currentValue / _challenge.targetValue.toDouble();
    
    if (performanceScore >= 1.0) {
      performanceText = 'Perfect score! Maximum rating boost!';
    } else if (performanceScore >= 0.8) {
      performanceText = 'Great performance! Significant rating boost!';
    } else if (performanceScore >= 0.6) {
      performanceText = 'Good effort! Moderate rating boost.';
    } else {
      performanceText = 'Completed! Small rating improvement.';
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Challenge Completed!',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events,
              color: Colors.amber,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Congratulations! You have completed the "${_challenge.title}" challenge.',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your final score: ${_userChallenge.currentValue}/${_challenge.targetValue} ${_challenge.unit}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            const Text(
              'Player Stats Improved!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$improvedStat has increased',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              performanceText,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.green,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (!_challenge.isWeekly) ...[
              const Text(
                'The next level challenge has been unlocked!',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.of(context).pushReplacementNamed('/challenges'); // Go back to challenges
                },
                child: const Text(
                  'Back to Challenges',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushNamed(context, '/player-stats'); // Navigate to stats without replacing current route
                },
                child: const Text(
                  'View Stats',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isCompleted = _userChallenge.status == ChallengeStatus.completed;
    final progress = _userChallenge.currentValue / _challenge.targetValue;
    final progressPercent = (progress * 100).toInt().clamp(0, 100);
    
    return Scaffold(
      appBar: CustomAppBar(
        title: _challenge.isWeekly ? 'Weekly Challenge' : 'Challenge',
        hasBackButton: true,
        onBackPressed: () {
          Navigator.of(context).pushReplacementNamed('/challenges');
        },
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/dashboard');
            },
          ),
        ],
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Challenge header
              _buildChallengeHeader(),
              
              const SizedBox(height: 24),
              
              // Progress section
              _buildProgressSection(isCompleted, progressPercent),
              
              const SizedBox(height: 24),
              
              // Tips section
              if (_challenge.tips != null && _challenge.tips!.isNotEmpty)
                _buildTipsSection(),
              
              const SizedBox(height: 24),
              
              // Record new attempt form
              if (!isCompleted)
                _buildRecordAttemptForm(),
              
              const SizedBox(height: 24),
              
              // Attempt history
              _buildAttemptHistory(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildChallengeHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category and level tag
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getCategoryColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _challenge.category.displayName,
                  style: TextStyle(
                    color: _getCategoryColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (!_challenge.isWeekly) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Level ${_challenge.level}',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (_challenge.deadline != null) ...[
                Icon(
                  Icons.access_time,
                  color: Colors.grey[400],
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  _getRemainingTime(),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Challenge title
          Text(
            _challenge.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Challenge description
          Text(
            _challenge.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Target
          Row(
            children: [
              const Icon(
                Icons.flag,
                color: Colors.amber,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Goal: ${_challenge.targetValue} ${_challenge.unit}',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressSection(bool isCompleted, int progressPercent) {
    final statusColor = isCompleted ? Colors.green : AppColors.primary;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (_userChallenge.currentValue / _challenge.targetValue).clamp(0.0, 1.0),
                    minHeight: 12,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 50,
                alignment: Alignment.center,
                child: Text(
                  '$progressPercent%',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current: ${_userChallenge.currentValue} ${_challenge.unit}',
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
              Text(
                'Target: ${_challenge.targetValue} ${_challenge.unit}',
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isCompleted) ...[
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'COMPLETED',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'on ${DateFormat('MMM d, yyyy').format(_userChallenge.completedAt!)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTipsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.amber,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Tips',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _challenge.tips!.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ',
                      style: TextStyle(
                        color: Colors.amber.withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _challenge.tips![index],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecordAttemptForm() {
    // Special form for 7 Days Juggle Challenge
    if (_challenge.title == '7 Days Juggle Challenge') {
      // Calculate which days have been recorded
      final recordedDays = <int>{};
      if (_userChallenge.attempts != null) {
        for (final attempt in _userChallenge.attempts!) {
          recordedDays.add(attempt.timestamp.day);
        }
      }
      
      // Get today's day number
      final today = DateTime.now().day;
      
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Record Your Daily Juggling',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Record your best juggling streak each day. You need to record for 7 different days to complete the challenge.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Days Recorded: ${recordedDays.length} of 7',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _valueController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Today\'s Best Streak',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      hintText: 'How many juggles?',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: recordedDays.contains(today) 
                      ? null  // Disable if already recorded today
                      : _recordAttempt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA500),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                  ),
                  child: Text(
                    recordedDays.contains(today) ? 'Already Recorded Today' : 'Record Today',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                hintText: 'Any tips or techniques you want to remember?',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.black.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Standard form for other challenges
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Record New Attempt',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Result (${_challenge.unit})',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              hintText: 'Enter your result',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.black.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              hintText: 'Any additional notes about your attempt',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.black.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _recordAttempt,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA500),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'RECORD ATTEMPT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAttemptHistory() {
    final attempts = _userChallenge.attempts;
    
    if (attempts == null || attempts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No attempts recorded yet',
            style: TextStyle(
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }
    
    // Sort attempts by timestamp (most recent first)
    final sortedAttempts = List<ChallengeAttempt>.from(attempts)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _challenge.title == '7 Days Juggle Challenge' 
                ? 'Daily Records' 
                : 'Attempt History',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedAttempts.length,
            itemBuilder: (context, index) {
              final attempt = sortedAttempts[index];
              final dateFormat = DateFormat('MMM d, yyyy');
              final timeFormat = DateFormat('h:mm a');
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateFormat.format(attempt.timestamp),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          timeFormat.format(attempt.timestamp),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${attempt.value} ${_challenge.unit == 'days' ? 'juggles' : _challenge.unit}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Show icon if it's a personal best
                        if (index == 0 && _challenge.title != '7 Days Juggle Challenge') ...[
                          const Icon(
                            Icons.emoji_events,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Best',
                            style: TextStyle(
                              color: Colors.amber.shade300,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (attempt.notes != null && attempt.notes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        attempt.notes!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Color _getCategoryColor() {
    switch (_challenge.category) {
      case ChallengeCategory.passing:
        return Colors.blue;
      case ChallengeCategory.shooting:
        return Colors.red;
      case ChallengeCategory.dribbling:
        return Colors.orange;
      case ChallengeCategory.fitness:
        return Colors.teal;
      case ChallengeCategory.defense:
        return Colors.purple;
      case ChallengeCategory.goalkeeping:
        return Colors.yellow;
      case ChallengeCategory.tactical:
        return Colors.indigo;
      case ChallengeCategory.weekly:
        return Colors.amber;
      case ChallengeCategory.wallTouches:
        return Colors.green;
    }
  }
  
  String _getRemainingTime() {
    if (_challenge.deadline == null) {
      return 'No deadline';
    }
    
    final now = DateTime.now();
    final difference = _challenge.deadline!.difference(now);
    
    if (difference.isNegative) {
      return 'Expired';
    }
    
    final days = difference.inDays;
    if (days > 0) {
      return '$days day${days > 1 ? 's' : ''} left';
    }
    
    final hours = difference.inHours;
    if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''} left';
    }
    
    final minutes = difference.inMinutes;
    return '$minutes minute${minutes > 1 ? 's' : ''} left';
  }
} 