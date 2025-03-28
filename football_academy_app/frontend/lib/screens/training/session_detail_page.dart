import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/training_plan.dart';
import '../../models/exercise.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/exercise_service.dart';
import '../../services/training_plan_service.dart';
import '../exercises/exercise_detail_page.dart';
import 'package:intl/intl.dart';

class SessionDetailPage extends StatefulWidget {
  final String planId;
  final int weekNumber;
  final TrainingSession session;
  final Function(String)? onSessionToggled;

  const SessionDetailPage({
    Key? key,
    required this.planId,
    required this.weekNumber,
    required this.session,
    this.onSessionToggled,
  }) : super(key: key);

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  late TrainingPlanService _trainingPlanService;
  late ExerciseService _exerciseService;
  
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _errorMessage;
  List<Exercise> _exercises = [];
  
  // Get user's first name for personalization
  String? _userName;
  User? _user;

  @override
  void initState() {
    super.initState();
    
    // Initialize services
    final authService = Provider.of<AuthService>(context, listen: false);
    _exerciseService = ExerciseService(authService);
    _trainingPlanService = TrainingPlanService(authService, _exerciseService);
    
    _loadUserInfo();
    _loadExercises();
  }

  Future<void> _loadUserInfo() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.getCurrentUser();
      setState(() {
        _userName = user.fullName.split(' ')[0];
        _user = user;
      });
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // In a real app, fetch exercises by IDs from the API
      // For now, use mock data
      final exercises = await Future.wait(
        widget.session.exercises.map((id) {
          // Convert string ID to int for the ExerciseService
          final numericId = int.tryParse(id.replaceAll('ex', '')) ?? 1;
          return _exerciseService.getExercise(numericId);
        }),
      );
      
      setState(() {
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSessionCompleted() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      // Mark the session as completed
      await _trainingPlanService.markSessionComplete(
        widget.planId,
        widget.weekNumber - 1, // Convert week number to zero-based index
        0, // We'll assume it's the first session for now without having the index
        !widget.session.isCompleted,
      );

      if (widget.onSessionToggled != null) {
        widget.onSessionToggled!(widget.session.id);
      }
      
      setState(() {
        _isUpdating = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.title),
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
                : _buildSessionDetails(),
      ),
      bottomNavigationBar: widget.session.isCompleted
          ? _buildCompletedBar()
          : _buildCompleteSessionButton(),
    );
  }

  Widget _buildSessionDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session header
          Card(
            color: Colors.white.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and intensity
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.session.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.session.getIntensityColor().withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.session.intensity,
                          style: TextStyle(
                            color: widget.session.getIntensityColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Info chips
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Icons.calendar_today,
                        label: _formatSessionDate(),
                      ),
                      const SizedBox(width: 16),
                      _buildInfoChip(
                        icon: Icons.timer,
                        label: '${widget.session.durationMinutes} min',
                      ),
                      const SizedBox(width: 16),
                      _buildInfoChip(
                        icon: Icons.fitness_center,
                        label: 'Week ${widget.weekNumber}',
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    widget.session.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Exercise list header
          Row(
            children: [
              const Text(
                'Exercises',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_exercises.length} exercises',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            _userName != null 
                ? 'Complete all exercises, $_userName. Focus on proper form.' 
                : 'Complete all exercises. Focus on proper form.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Exercise list
          ..._exercises.asMap().entries.map((entry) {
            final index = entry.key;
            final exercise = entry.value;
            return _buildExerciseCard(exercise, index);
          }),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.7),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise, int index) {
    // Get category color
    Color categoryColor;
    switch (exercise.category.toLowerCase()) {
      case 'dribbling':
        categoryColor = Colors.blue;
        break;
      case 'passing':
        categoryColor = Colors.green;
        break;
      case 'shooting':
        categoryColor = Colors.orange;
        break;
      case 'defending':
        categoryColor = Colors.red;
        break;
      case 'physical':
        categoryColor = Colors.purple;
        break;
      default:
        categoryColor = Colors.blueGrey;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExerciseDetailPage(
                exerciseId: _getExerciseNumericId(exercise.id),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise image with number overlay
            Stack(
              children: [
                // Image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: exercise.imageUrl != null
                      ? Image.network(
                          exercise.imageUrl!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback for invalid images
                            return Container(
                              height: 160,
                              width: double.infinity,
                              color: Colors.grey.shade800,
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          height: 160,
                          width: double.infinity,
                          color: categoryColor.withOpacity(0.3),
                          child: Center(
                            child: Icon(
                              Icons.sports_soccer,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                ),
                
                // Exercise number
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Category badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getCategoryIcon(exercise.category),
                          color: categoryColor,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          exercise.category,
                          style: TextStyle(
                            color: categoryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Exercise details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    exercise.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Duration and difficulty
                  Row(
                    children: [
                      Icon(
                        Icons.timer,
                        color: Colors.white.withOpacity(0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${exercise.durationMinutes} min',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.signal_cellular_alt,
                        color: Colors.white.withOpacity(0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        exercise.difficulty,
                        style: TextStyle(
                          color: _getDifficultyColor(exercise.difficulty),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Brief description (truncated)
                  Text(
                    _truncateDescription(exercise.description),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // View details button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExerciseDetailPage(
                              exerciseId: _getExerciseNumericId(exercise.id),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('View Details'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteSessionButton() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: ElevatedButton(
          onPressed: _isUpdating ? null : _toggleSessionCompleted,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: const Size(double.infinity, 0),
          ),
          child: _isUpdating
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Mark Session as Completed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCompletedBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.2),
          border: Border(
            top: BorderSide(
              color: Colors.green.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              _userName != null
                  ? 'Great job, $_userName! Session completed'
                  : 'Great job! Session completed',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'dribbling':
        return Icons.move_down;
      case 'passing':
        return Icons.swap_horiz;
      case 'shooting':
        return Icons.sports_soccer;
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

  String _truncateDescription(String description) {
    const maxLength = 100;
    if (description.length <= maxLength) {
      return description;
    }
    return '${description.substring(0, maxLength)}...';
  }
  
  int _getExerciseNumericId(String? stringId) {
    if (stringId == null) return 0;
    
    // Strip "ex" prefix and parse to int
    try {
      if (stringId.startsWith('ex')) {
        return int.parse(stringId.substring(2));
      } else {
        return int.parse(stringId);
      }
    } catch (e) {
      // Fallback to using hash code
      return stringId.hashCode;
    }
  }

  String _formatSessionDate() {
    // Just show date without the dayOfWeek
    final now = DateTime.now();
    final formatter = DateFormat('MMMM d, yyyy');
    return formatter.format(now);
  }
} 