import 'package:flutter/material.dart';
import '../../models/training_plan.dart';
import '../../services/exercise_service.dart';
import '../../models/exercise.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/gradient_background.dart';
import 'exercise_selector_page.dart';

class TrainingDayEditorPage extends StatefulWidget {
  final TrainingPlan trainingPlan;
  final String dayOfWeek;

  const TrainingDayEditorPage({
    Key? key,
    required this.trainingPlan,
    required this.dayOfWeek,
  }) : super(key: key);

  @override
  _TrainingDayEditorPageState createState() => _TrainingDayEditorPageState();
}

class _TrainingDayEditorPageState extends State<TrainingDayEditorPage> {
  late TrainingPlan _currentPlan;
  late bool _isTrainingDay;
  late List<TrainingPlanExercise> _exercises;

  @override
  void initState() {
    super.initState();
    _currentPlan = widget.trainingPlan;
    _isTrainingDay = _currentPlan.trainingDays.contains(widget.dayOfWeek);
    _exercises = _currentPlan.getExercisesForDay(widget.dayOfWeek);
  }

  void _toggleTrainingDay() {
    setState(() {
      if (_isTrainingDay) {
        _currentPlan = _currentPlan.removeTrainingDay(widget.dayOfWeek);
        _exercises = [];
      } else {
        _currentPlan = _currentPlan.addTrainingDay(widget.dayOfWeek);
      }
      _isTrainingDay = !_isTrainingDay;
    });
  }

  Future<void> _addExercise() async {
    if (!_isTrainingDay) {
      // If it's not a training day, make it one first
      setState(() {
        _currentPlan = _currentPlan.addTrainingDay(widget.dayOfWeek);
        _isTrainingDay = true;
      });
    }

    // Navigate to exercise selector page
    final selectedExercise = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (context) => const ExerciseSelectorPage(),
      ),
    );

    if (selectedExercise != null && mounted) {
      setState(() {
        final trainingPlanExercise = TrainingPlanExercise.fromExercise(selectedExercise);
        _currentPlan = _currentPlan.addExercise(widget.dayOfWeek, trainingPlanExercise);
        _exercises = _currentPlan.getExercisesForDay(widget.dayOfWeek);
      });
    }
  }

  void _removeExercise(TrainingPlanExercise exercise) {
    setState(() {
      _currentPlan = _currentPlan.removeExercise(widget.dayOfWeek, exercise);
      _exercises = _currentPlan.getExercisesForDay(widget.dayOfWeek);
    });
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    setState(() {
      final exercise = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, exercise);
      
      // Create updated schedule manually
      final updatedSchedule = Map<String, List<TrainingPlanExercise>>.from(_currentPlan.schedule);
      updatedSchedule[widget.dayOfWeek] = List.from(_exercises);
      
      _currentPlan = TrainingPlan(
        id: _currentPlan.id,
        title: _currentPlan.title,
        description: _currentPlan.description,
        createdAt: _currentPlan.createdAt,
        updatedAt: DateTime.now(),
        schedule: updatedSchedule,
        trainingDays: _currentPlan.trainingDays,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final int totalDuration = _exercises.fold(
      0, 
      (sum, exercise) => sum + exercise.durationMinutes
    );

    return Scaffold(
      appBar: CustomAppBar(
        title: '${widget.dayOfWeek} Training',
        actions: [
          IconButton(
            icon: Icon(
              _isTrainingDay ? Icons.visibility : Icons.visibility_off,
              color: _isTrainingDay ? AppColors.primary : Colors.grey,
            ),
            onPressed: _toggleTrainingDay,
            tooltip: _isTrainingDay ? 'Remove Training Day' : 'Add Training Day',
          ),
        ],
      ),
      body: GradientBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, totalDuration),
            Expanded(
              child: _isTrainingDay
                  ? _buildExercisesList()
                  : _buildNoTrainingView(),
            ),
          ],
        ),
      ),
      floatingActionButton: _isTrainingDay
          ? FloatingActionButton(
              onPressed: _addExercise,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader(BuildContext context, int totalDuration) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.secondaryBackground.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isTrainingDay 
              ? '${widget.dayOfWeek} Training Plan' 
              : 'No Training on ${widget.dayOfWeek}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_isTrainingDay) ...[
            Row(
              children: [
                const Icon(Icons.timer, size: 16, color: Colors.white70),
                const SizedBox(width: 4),
                Text(
                  'Total Duration: $totalDuration minutes',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.fitness_center, size: 16, color: Colors.white70),
                const SizedBox(width: 4),
                Text(
                  'Exercises: ${_exercises.length}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExercisesList() {
    if (_exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.fitness_center,
              size: 64,
              color: Colors.white30,
            ),
            const SizedBox(height: 16),
            Text(
              'No exercises added yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.add),
              label: const Text('Add Exercise'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _exercises.length,
      onReorder: _reorderExercises,
      itemBuilder: (context, index) {
        final exercise = _exercises[index];
        return _buildExerciseCard(exercise, index);
      },
    );
  }

  Widget _buildExerciseCard(TrainingPlanExercise exercise, int index) {
    Color difficultyColor;
    switch (exercise.difficulty.toLowerCase()) {
      case 'beginner':
        difficultyColor = Colors.green;
        break;
      case 'intermediate':
        difficultyColor = Colors.orange;
        break;
      case 'advanced':
        difficultyColor = Colors.red;
        break;
      default:
        difficultyColor = Colors.blue;
    }

    return Card(
      key: Key('exercise_${exercise.id}_$index'),
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.cardBackground,
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${exercise.durationMinutes}m',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: difficultyColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              exercise.difficulty,
                              style: TextStyle(
                                color: difficultyColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              exercise.category,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: () => _removeExercise(exercise),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              exercise.description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            if (exercise.equipment != null && exercise.equipment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: exercise.equipment!
                    .map((e) => Chip(
                          label: Text(
                            e,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.grey.withOpacity(0.3),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.drag_handle, 
                      size: 16, 
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Drag to reorder',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (exercise.videoUrl != null)
                  Row(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        color: AppColors.accent,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Watch Video',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTrainingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.sports_soccer,
            size: 80,
            color: Colors.white24,
          ),
          const SizedBox(height: 24),
          Text(
            'No Training Scheduled',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This is a rest day. Would you like to add training?',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _toggleTrainingDay,
            icon: const Icon(Icons.add),
            label: const Text('Add Training'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _currentPlan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 