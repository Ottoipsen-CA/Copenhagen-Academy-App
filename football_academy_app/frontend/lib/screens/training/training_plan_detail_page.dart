import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/training_plan.dart';
import '../../services/auth_service.dart';
import '../../services/exercise_service.dart';
import '../../services/training_plan_service.dart';
import 'session_detail_page.dart';

class TrainingPlanDetailPage extends StatefulWidget {
  final String planId;

  const TrainingPlanDetailPage({
    Key? key,
    required this.planId,
  }) : super(key: key);

  @override
  State<TrainingPlanDetailPage> createState() => _TrainingPlanDetailPageState();
}

class _TrainingPlanDetailPageState extends State<TrainingPlanDetailPage> {
  late TrainingPlanService _trainingPlanService;
  TrainingPlan? _plan;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedWeekIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // Initialize services
    final authService = Provider.of<AuthService>(context, listen: false);
    final exerciseService = ExerciseService(authService);
    _trainingPlanService = TrainingPlanService(authService, exerciseService);
    
    _loadTrainingPlan();
  }

  Future<void> _loadTrainingPlan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final plan = await _trainingPlanService.getTrainingPlan(widget.planId);
      
      setState(() {
        _plan = plan;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_plan?.title ?? 'Training Plan'),
        centerTitle: true,
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
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _errorMessage != null
                ? Center(
                    child: Text(
                      'Error: $_errorMessage',
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                : _plan == null
                    ? const Center(
                        child: Text(
                          'Training plan not found',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : _buildPlanDetails(),
      ),
    );
  }

  Widget _buildPlanDetails() {
    // Get the first focus area for coloring
    final String firstFocusArea = _plan!.focusArea.isNotEmpty ? _plan!.focusArea[0] : "General";
    final Color focusAreaColor = _getFocusAreaColor(firstFocusArea);
    
    return Column(
      children: [
        // Header section with plan info
        _buildPlanHeader(focusAreaColor),
        
        // Week selection tabs
        _buildWeekTabs(),
        
        // Week details
        Expanded(
          child: _buildWeekDetails(),
        ),
      ],
    );
  }

  Widget _buildPlanHeader(Color focusAreaColor) {
    // Get the first focus area for icon
    final String firstFocusArea = _plan!.focusArea.isNotEmpty ? _plan!.focusArea[0] : "General";
    
    // Calculate overall progress
    final totalSessions = _plan!.weeks.fold(
      0,
      (total, week) => total + week.sessions.length,
    );
    
    final completedSessions = _plan!.weeks.fold(
      0,
      (total, week) => total +
          week.sessions.where((session) => session.isCompleted).length,
    );
    
    final progress = totalSessions > 0 ? completedSessions / totalSessions : 0.0;
    
    // Format dates
    final dateFormat = DateFormat('MMM d, yyyy');
    final startDate = dateFormat.format(_plan!.startDate);
    final endDate = dateFormat.format(
      _plan!.startDate.add(Duration(days: _plan!.durationWeeks * 7)),
    );
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and focus area
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: focusAreaColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getFocusAreaIcon(firstFocusArea),
                  color: focusAreaColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _plan!.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_plan!.focusArea.join("/")} • ${_plan!.playerLevel} Level',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Overall Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$completedSessions of $totalSessions sessions completed',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(focusAreaColor),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Date range
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.white.withOpacity(0.7),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '$startDate - $endDate (${_plan!.durationWeeks} weeks)',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekTabs() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _plan!.weeks.length,
        itemBuilder: (context, index) {
          final week = _plan!.weeks[index];
          final isSelected = _selectedWeekIndex == index;
          
          // Calculate completion percentage for this week
          final totalSessions = week.sessions.length;
          final completedSessions = week.sessions.where((s) => s.isCompleted).length;
          final completionPercentage = totalSessions > 0
              ? completedSessions / totalSessions * 100
              : 0;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedWeekIndex = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? Colors.orange
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
                color: isSelected
                    ? Colors.white.withOpacity(0.1)
                    : Colors.transparent,
              ),
              child: Center(
                child: Row(
                  children: [
                    Text(
                      'Week ${week.weekNumber}',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.7),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (completionPercentage == 100)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeekDetails() {
    if (_selectedWeekIndex >= _plan!.weeks.length) {
      return const Center(
        child: Text('Week not found', style: TextStyle(color: Colors.white)),
      );
    }
    
    final selectedWeek = _plan!.weeks[_selectedWeekIndex];
    
    return Column(
      children: [
        // Week header with description and difficulty
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black.withOpacity(0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedWeek.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(selectedWeek.difficulty).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      selectedWeek.difficulty,
                      style: TextStyle(
                        color: _getDifficultyColor(selectedWeek.difficulty),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                selectedWeek.description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        
        // Sessions list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: selectedWeek.sessions.length,
            itemBuilder: (context, index) {
              final session = selectedWeek.sessions[index];
              return _buildSessionCard(session, selectedWeek.weekNumber);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(TrainingSession session, int weekNumber) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SessionDetailPage(
                planId: widget.planId,
                weekNumber: weekNumber,
                session: session,
              ),
            ),
          ).then((_) {
            // Refresh data when returning from session detail
            _loadTrainingPlan();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Session status indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: session.isCompleted
                      ? Colors.green
                      : Colors.white.withOpacity(0.1),
                  border: session.isCompleted
                      ? null
                      : Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                ),
                child: session.isCompleted
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
              
              const SizedBox(width: 16),
              
              // Session info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: session.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: Colors.green,
                        decorationThickness: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Session meta info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: session.getIntensityColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      session.intensity,
                      style: TextStyle(
                        color: session.getIntensityColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${session.durationMinutes} min',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 8),
              
              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getFocusAreaColor(String focusArea) {
    switch (focusArea.toLowerCase()) {
      case 'shooting':
        return Colors.orange;
      case 'passing':
        return Colors.green;
      case 'dribbling':
        return Colors.blue;
      case 'defending':
        return Colors.red;
      case 'physical':
        return Colors.purple;
      case 'ball control':
        return Colors.teal;
      case 'pace':
        return Colors.amber;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getFocusAreaIcon(String focusArea) {
    switch (focusArea.toLowerCase()) {
      case 'shooting':
        return Icons.sports_soccer;
      case 'passing':
        return Icons.swap_horiz;
      case 'dribbling':
        return Icons.move_down;
      case 'defending':
        return Icons.shield;
      case 'physical':
        return Icons.fitness_center;
      case 'ball control':
        return Icons.sports_handball;
      case 'pace':
        return Icons.speed;
      default:
        return Icons.sports;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
      case 'easy':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }
} 