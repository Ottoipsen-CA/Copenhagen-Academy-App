import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/training_schedule.dart';
import '../../services/training_schedule_service.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/gradient_background.dart';
import 'add_match_dialog.dart';
import 'add_training_session_dialog.dart';

class DayDetailPage extends StatefulWidget {
  final TrainingDay day;
  final WeeklyTrainingSchedule schedule;

  const DayDetailPage({
    Key? key,
    required this.day,
    required this.schedule,
  }) : super(key: key);

  @override
  _DayDetailPageState createState() => _DayDetailPageState();
}

class _DayDetailPageState extends State<DayDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TrainingDay _day;
  final _goalsController = TextEditingController();
  bool _isEditingGoals = false;

  @override
  void initState() {
    super.initState();
    _day = widget.day;
    _tabController = TabController(length: 3, vsync: this);
    _goalsController.text = _day.goals ?? '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _goalsController.dispose();
    super.dispose();
  }

  Future<void> _addTrainingSession() async {
    final newSession = await showDialog<TrainingSession>(
      context: context,
      builder: (context) => AddTrainingSessionDialog(),
    );

    if (newSession != null) {
      try {
        final updatedDay = await TrainingScheduleService.addTrainingSession(
          widget.schedule,
          _day,
          newSession,
        );
        setState(() {
          _day = updatedDay;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add training session: $e')),
        );
      }
    }
  }

  Future<void> _addMatch() async {
    final newMatch = await showDialog<Match>(
      context: context,
      builder: (context) => AddMatchDialog(),
    );

    if (newMatch != null) {
      try {
        final updatedDay = await TrainingScheduleService.addMatch(
          widget.schedule,
          _day,
          newMatch,
        );
        setState(() {
          _day = updatedDay;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add match: $e')),
        );
      }
    }
  }

  Future<void> _saveGoals() async {
    try {
      final updatedDay = await TrainingScheduleService.updateDayGoals(
        widget.schedule,
        _day,
        _goalsController.text,
      );
      setState(() {
        _day = updatedDay;
        _isEditingGoals = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save goals: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '${_day.day} Schedule',
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // Return the updated day to the previous screen
              Navigator.pop(context, _day);
            },
          ),
        ],
      ),
      body: GradientBackground(
        child: Column(
          children: [
            Material(
              color: AppColors.secondaryBackground,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.accent,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.fitness_center),
                    text: 'Training',
                  ),
                  Tab(
                    icon: Icon(Icons.sports_soccer),
                    text: 'Matches',
                  ),
                  Tab(
                    icon: Icon(Icons.flag),
                    text: 'Goals',
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTrainingSessionsTab(),
                  _buildMatchesTab(),
                  _buildGoalsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    switch (_tabController.index) {
      case 0:
        return FloatingActionButton(
          onPressed: _addTrainingSession,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add),
          tooltip: 'Add Training Session',
        );
      case 1:
        return FloatingActionButton(
          onPressed: _addMatch,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add),
          tooltip: 'Add Match',
        );
      case 2:
        if (!_isEditingGoals) {
          return FloatingActionButton(
            onPressed: () {
              setState(() {
                _isEditingGoals = true;
              });
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.edit),
            tooltip: 'Edit Goals',
          );
        } else {
          return FloatingActionButton(
            onPressed: _saveGoals,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.save),
            tooltip: 'Save Goals',
          );
        }
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTrainingSessionsTab() {
    if (_day.sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No training sessions scheduled',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _addTrainingSession,
              icon: const Icon(Icons.add),
              label: const Text('Add Training Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _day.sessions.length,
      itemBuilder: (context, index) {
        final session = _day.sessions[index];
        return Dismissible(
          key: Key('session_${index}_${session.title}'),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            setState(() {
              final updatedSessions = List<TrainingSession>.from(_day.sessions);
              updatedSessions.removeAt(index);
              _day = _day.copyWith(sessions: updatedSessions);
            });
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: AppColors.cardBackground,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          session.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getIntensityColor(session.intensity).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.whatshot,
                              color: Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Intensity: ${session.intensity}',
                              style: TextStyle(
                                color: _getIntensityColor(session.intensity),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        session.timeRange,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (session.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          session.location!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (session.description != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.description,
                                color: Colors.blue,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Description:',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            session.description!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (session.type != null) ...[
                    const SizedBox(height: 12),
                    Chip(
                      label: Text(
                        session.type!,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: Colors.blue.withOpacity(0.2),
                    ),
                  ],
                  
                  // Performance Rating
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Performance Rating',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildRatingStars(
                        session.performanceRating ?? 0, 
                        (rating) => _updateSessionRating(index, rating),
                      ),
                    ],
                  ),
                  
                  // Pre and Post Training Evaluation section
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildEvaluationSection(
                          session, 
                          index, 
                          isPre: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildEvaluationSection(
                          session, 
                          index, 
                          isPre: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _updateSessionRating(int sessionIndex, int rating) {
    setState(() {
      final updatedSessions = List<TrainingSession>.from(_day.sessions);
      updatedSessions[sessionIndex] = updatedSessions[sessionIndex].copyWith(
        performanceRating: rating == updatedSessions[sessionIndex].performanceRating ? null : rating,
      );
      _day = _day.copyWith(sessions: updatedSessions);
    });
  }
  
  Widget _buildRatingStars(int currentRating, Function(int) onRatingChanged) {
    return Row(
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isSelected = starValue <= currentRating;
        return GestureDetector(
          onTap: () => onRatingChanged(starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              isSelected ? Icons.star : Icons.star_border,
              color: isSelected ? Colors.amber : Colors.white.withOpacity(0.5),
              size: 22,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEvaluationSection(TrainingSession session, int sessionIndex, {required bool isPre}) {
    final evaluationType = isPre ? 'Pre-Training' : 'Post-Training';
    final iconData = isPre ? Icons.assignment : Icons.assignment_turned_in;
    final colorScheme = isPre ? Colors.amber : Colors.green;
    
    // Get the current evaluation text or empty string if not set
    final evaluationText = isPre 
        ? (session.preEvaluation ?? '') 
        : (session.postEvaluation ?? '');
    
    final hasEvaluation = evaluationText.isNotEmpty;
    
    return InkWell(
      onTap: () => _showEvaluationDialog(sessionIndex, isPre),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  iconData,
                  color: colorScheme,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  evaluationType,
                  style: TextStyle(
                    color: colorScheme,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  hasEvaluation ? Icons.check_circle : Icons.add_circle_outline,
                  color: hasEvaluation ? colorScheme : Colors.grey,
                  size: 16,
                ),
              ],
            ),
            if (hasEvaluation) ...[
              const SizedBox(height: 4),
              Text(
                evaluationText,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                'Tap to add...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Future<void> _showEvaluationDialog(int sessionIndex, bool isPre) async {
    final evaluationType = isPre ? 'Pre-Training' : 'Post-Training';
    final session = _day.sessions[sessionIndex];
    final controller = TextEditingController();
    
    if (isPre && session.preEvaluation != null) {
      controller.text = session.preEvaluation!;
    } else if (!isPre && session.postEvaluation != null) {
      controller.text = session.postEvaluation!;
    }
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: Text(
          '$evaluationType Evaluation',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPre
                  ? 'What are your objectives for this training?'
                  : 'How did the training go? What did you learn?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              maxLines: 5,
              decoration: InputDecoration(
                hintText: isPre
                    ? 'Enter your goals and focus areas...'
                    : 'Enter your achievements and reflections...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.black.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
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
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      setState(() {
        final updatedSessions = List<TrainingSession>.from(_day.sessions);
        if (isPre) {
          updatedSessions[sessionIndex] = updatedSessions[sessionIndex]
              .copyWith(preEvaluation: result.isEmpty ? null : result);
        } else {
          updatedSessions[sessionIndex] = updatedSessions[sessionIndex]
              .copyWith(postEvaluation: result.isEmpty ? null : result);
        }
        _day = _day.copyWith(sessions: updatedSessions);
      });
    }
  }

  Widget _buildMatchesTab() {
    if (_day.matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_soccer,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No matches scheduled',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _addMatch,
              icon: const Icon(Icons.add),
              label: const Text('Add Match'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _day.matches.length,
      itemBuilder: (context, index) {
        final match = _day.matches[index];
        final matchTime = DateFormat('HH:mm').format(match.dateTime);
        
        return Dismissible(
          key: Key('match_${index}_${match.opponent}'),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            setState(() {
              final updatedMatches = List<Match>.from(_day.matches);
              updatedMatches.removeAt(index);
              _day = _day.copyWith(matches: updatedMatches);
            });
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: AppColors.cardBackground,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sports_soccer,
                          color: Colors.red,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              match.matchTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              match.isHomeGame ? 'Home Game' : 'Away Game',
                              style: TextStyle(
                                color: match.isHomeGame ? Colors.green : Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (match.competition != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            match.competition!,
                            style: const TextStyle(
                              color: Colors.purple,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        matchTime,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (match.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          match.location!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  // Description section (if available)
                  if (match.description != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.description,
                                color: Colors.blue,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Description:',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            match.description!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Performance Rating
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Performance Rating',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildRatingStars(
                        match.performanceRating ?? 0, 
                        (rating) => _updateMatchRating(index, rating),
                      ),
                    ],
                  ),
                  
                  // Pre-match and Post-match notes sections
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMatchEvaluationSection(
                          match, 
                          index, 
                          isPre: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMatchEvaluationSection(
                          match, 
                          index, 
                          isPre: false,
                        ),
                      ),
                    ],
                  ),
                  
                  // Add Description button if no description
                  if (match.description == null) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () => _showMatchDescriptionDialog(index),
                        icon: const Icon(Icons.description, size: 16),
                        label: const Text('Add Match Description'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(color: Colors.white.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _updateMatchRating(int matchIndex, int rating) {
    setState(() {
      final updatedMatches = List<Match>.from(_day.matches);
      updatedMatches[matchIndex] = updatedMatches[matchIndex].copyWith(
        performanceRating: rating == updatedMatches[matchIndex].performanceRating ? null : rating,
      );
      _day = _day.copyWith(matches: updatedMatches);
    });
  }
  
  Widget _buildMatchEvaluationSection(Match match, int matchIndex, {required bool isPre}) {
    final evaluationType = isPre ? 'Pre-Match' : 'Post-Match';
    final iconData = isPre ? Icons.assignment : Icons.assessment;
    final colorScheme = isPre ? Colors.amber : Colors.green;
    
    // Get the current evaluation text or empty string if not set
    final evaluationText = isPre 
        ? (match.preMatchNotes ?? '') 
        : (match.postMatchAnalysis ?? '');
    
    final rating = isPre 
        ? (match.preMatchRating ?? 0) 
        : (match.postMatchRating ?? 0);
    
    final hasEvaluation = evaluationText.isNotEmpty;
    
    return InkWell(
      onTap: () => _showMatchEvaluationDialog(matchIndex, isPre),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  iconData,
                  color: colorScheme,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  evaluationType,
                  style: TextStyle(
                    color: colorScheme,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (rating > 0) ...[
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 10,
                      );
                    }),
                  ),
                ] else ... [
                  Icon(
                    hasEvaluation ? Icons.check_circle : Icons.add_circle_outline,
                    color: hasEvaluation ? colorScheme : Colors.grey,
                    size: 16,
                  ),
                ],
              ],
            ),
            if (hasEvaluation) ...[
              const SizedBox(height: 4),
              Text(
                evaluationText,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                'Tap to add...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Future<void> _showMatchDescriptionDialog(int matchIndex) async {
    final match = _day.matches[matchIndex];
    final controller = TextEditingController();
    
    if (match.description != null) {
      controller.text = match.description!;
    }
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: const Text(
          'Match Description',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add details about this match:',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter match details, tactics, or other notes...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.black.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
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
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      setState(() {
        final updatedMatches = List<Match>.from(_day.matches);
        updatedMatches[matchIndex] = updatedMatches[matchIndex].copyWith(
          description: result.isEmpty ? null : result,
        );
        _day = _day.copyWith(matches: updatedMatches);
      });
    }
  }
  
  Future<void> _showMatchEvaluationDialog(int matchIndex, bool isPre) async {
    final evaluationType = isPre ? 'Pre-Match' : 'Post-Match';
    final match = _day.matches[matchIndex];
    final controller = TextEditingController();
    int rating = isPre 
        ? (match.preMatchRating ?? 0) 
        : (match.postMatchRating ?? 0);
    
    if (isPre && match.preMatchNotes != null) {
      controller.text = match.preMatchNotes!;
    } else if (!isPre && match.postMatchAnalysis != null) {
      controller.text = match.postMatchAnalysis!;
    }
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.secondaryBackground,
          title: Text(
            '$evaluationType Evaluation',
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPre
                    ? 'What are your goals for this match?'
                    : 'How did the match go? What did you learn?',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: isPre
                      ? 'Enter your preparation and strategy...'
                      : 'Enter your performance analysis and learnings...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Performance Rating Section - show for both pre and post match
              Text(
                isPre ? 'Preparation Rating' : 'Performance Rating',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  final isSelected = starValue <= rating;
                  return GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        rating = starValue == rating ? 0 : starValue;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        isSelected ? Icons.star : Icons.star_border,
                        color: isSelected ? Colors.amber : Colors.white.withOpacity(0.5),
                        size: 28,
                      ),
                    ),
                  );
                }),
              ),
            ],
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
              onPressed: () => Navigator.pop(context, {
                'notes': controller.text,
                'rating': rating,
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        final updatedMatches = List<Match>.from(_day.matches);
        if (isPre) {
          updatedMatches[matchIndex] = updatedMatches[matchIndex].copyWith(
            preMatchNotes: result['notes'].isEmpty ? null : result['notes'],
            preMatchRating: result['rating'] == 0 ? null : result['rating'],
          );
        } else {
          updatedMatches[matchIndex] = updatedMatches[matchIndex].copyWith(
            postMatchAnalysis: result['notes'].isEmpty ? null : result['notes'],
            postMatchRating: result['rating'] == 0 ? null : result['rating'],
          );
        }
        _day = _day.copyWith(matches: updatedMatches);
      });
    }
  }

  Widget _buildGoalsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _isEditingGoals
          ? _buildGoalsEditForm()
          : _buildGoalsDisplay(),
    );
  }

  Widget _buildGoalsEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What are your goals for this day?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _goalsController,
          style: const TextStyle(color: Colors.white),
          maxLines: 8,
          decoration: InputDecoration(
            hintText: 'Enter your goals...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _goalsController.text = _day.goals ?? '';
                  _isEditingGoals = false;
                });
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _saveGoals,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalsDisplay() {
    if (_day.goals == null || _day.goals!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No goals set for this day yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isEditingGoals = true;
                });
              },
              icon: const Icon(Icons.edit),
              label: const Text('Set Goals'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.flag,
              color: Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Goals for today:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(
                Icons.edit,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isEditingGoals = true;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.orange.withOpacity(0.3),
            ),
          ),
          child: Text(
            _day.goals!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Color _getIntensityColor(int intensity) {
    switch (intensity) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
} 