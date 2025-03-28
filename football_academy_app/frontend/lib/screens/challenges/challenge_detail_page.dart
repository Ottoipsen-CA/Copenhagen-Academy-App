import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/challenge.dart';
import '../../services/challenge_service.dart';
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
  
  void _showCompletionDialog() {
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.white70),
            ),
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
          TextFormField(
            controller: _noteController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              hintText: 'Add notes about this attempt...',
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
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Record Attempt',
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
          const Text(
            'Attempt History',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedAttempts.length,
            separatorBuilder: (context, index) => const Divider(
              color: Colors.white24,
              height: 24,
            ),
            itemBuilder: (context, index) {
              final attempt = sortedAttempts[index];
              final isHighest = attempt.value == _userChallenge.currentValue;
              
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMM d').format(attempt.timestamp),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(attempt.timestamp),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Value and notes column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${attempt.value} ${_challenge.unit}',
                              style: TextStyle(
                                color: isHighest ? Colors.amber : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (isHighest) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.emoji_events,
                                color: Colors.amber,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                        if (attempt.notes != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            attempt.notes!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
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