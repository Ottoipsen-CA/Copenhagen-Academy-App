import 'package:flutter/material.dart';
import '../../models/training_plan.dart';
import '../../services/training_plan_service.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/gradient_background.dart';
import 'training_day_editor_page.dart';

class TrainingPlanPage extends StatefulWidget {
  static const String routeName = '/training-plan';

  const TrainingPlanPage({Key? key}) : super(key: key);

  @override
  _TrainingPlanPageState createState() => _TrainingPlanPageState();
}

class _TrainingPlanPageState extends State<TrainingPlanPage> {
  late Future<TrainingPlan> _trainingPlanFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchTrainingPlan();
  }

  void _fetchTrainingPlan() {
    setState(() {
      _isLoading = true;
      // For development, use mock data
      _trainingPlanFuture = TrainingPlanService.getMockTrainingPlan();
      // In production, use this:
      // _trainingPlanFuture = TrainingPlanService.getTrainingPlan();
    });
  }

  Future<void> _saveTrainingPlan(TrainingPlan plan) async {
    setState(() {
      _isLoading = true;
    });

    final success = await TrainingPlanService.saveTrainingPlan(plan);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _fetchTrainingPlan();
        } else {
          // Show error snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save training plan'))
          );
        }
      });
    }
  }

  Future<void> _editDay(BuildContext context, TrainingPlan plan, String day) async {
    final updatedPlan = await Navigator.push<TrainingPlan>(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingDayEditorPage(
          trainingPlan: plan,
          dayOfWeek: day,
        ),
      ),
    );

    if (updatedPlan != null) {
      await _saveTrainingPlan(updatedPlan);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Weekly Training Plan'),
      body: GradientBackground(
        child: FutureBuilder<TrainingPlan>(
          future: _trainingPlanFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('No training plan found'));
            }

            final plan = snapshot.data!;
            return _buildContent(context, plan);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TrainingPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, plan),
        const SizedBox(height: 16),
        Expanded(
          child: _buildWeeklySchedule(context, plan),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, TrainingPlan plan) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            plan.description,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                context, 
                '${plan.totalExercises}', 
                'Exercises', 
                Icons.fitness_center
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                context, 
                '${plan.totalDuration}', 
                'Minutes', 
                Icons.timer
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                context, 
                '${plan.trainingDays.length}', 
                'Days', 
                Icons.calendar_today
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBackground.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySchedule(BuildContext context, TrainingPlan plan) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: TrainingPlan.allWeekdays.length,
      itemBuilder: (context, index) {
        final day = TrainingPlan.allWeekdays[index];
        final isTrainingDay = plan.trainingDays.contains(day);
        final exercises = plan.getExercisesForDay(day);
        
        return _buildDayCard(context, plan, day, isTrainingDay, exercises);
      },
    );
  }

  Widget _buildDayCard(
    BuildContext context, 
    TrainingPlan plan, 
    String day, 
    bool isTrainingDay, 
    List<TrainingPlanExercise> exercises
  ) {
    final duration = plan.getDayDuration(day);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isTrainingDay 
          ? const BorderSide(color: AppColors.primary, width: 2) 
          : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _editDay(context, plan, day),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    day,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isTrainingDay ? AppColors.primary : Colors.white54,
                    ),
                  ),
                  if (isTrainingDay)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, 
                        vertical: 4
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        duration > 0 
                          ? '$duration min' 
                          : 'Rest Day',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, 
                        vertical: 4
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'No Training',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              if (isTrainingDay && exercises.isNotEmpty) ...[
                const SizedBox(height: 16),
                for (final exercise in exercises)
                  _buildExerciseItem(context, exercise),
              ],
              if (isTrainingDay && exercises.isEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'No exercises scheduled. Tap to add exercises.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.edit, 
                    size: 16, 
                    color: isTrainingDay ? AppColors.primary : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isTrainingDay ? 'Edit Schedule' : 'Add Training',
                    style: TextStyle(
                      color: isTrainingDay ? AppColors.primary : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseItem(BuildContext context, TrainingPlanExercise exercise) {
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  ),
                ),
                Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8, top: 4),
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
                      margin: const EdgeInsets.only(top: 4),
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
          if (exercise.videoUrl != null)
            Icon(
              Icons.play_circle_outline,
              color: AppColors.accent,
              size: 24,
            ),
        ],
      ),
    );
  }
} 