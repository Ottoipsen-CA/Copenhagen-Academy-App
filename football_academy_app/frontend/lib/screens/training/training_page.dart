import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/exercise.dart';
import '../../models/training_schedule.dart';
import '../../services/exercise_service.dart';
import '../../services/training_schedule_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/navigation_drawer.dart';
import '../../theme/colors.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _exerciseTabController;
  late ExerciseService _exerciseService;
  
  // Exercise library state
  List<Exercise> _allExercises = [];
  List<Exercise> _favoriteExercises = [];
  bool _isLoadingExercises = true;
  String? _exerciseError;
  
  // Training schedule state
  late Future<WeeklyTrainingSchedule> _scheduleFuture;
  final _weeklyGoalsController = TextEditingController();
  bool _isEditingWeeklyGoals = false;
  
  // Filter values
  String? _selectedDifficulty;
  String _searchQuery = '';
  
  // Available filter options
  final List<String> _difficulties = [
    'All Difficulties',
    'Beginner',
    'Intermediate',
    'Advanced',
  ];
  
  // Technical areas/categories
  final List<String> _technicalAreas = [
    'All',
    'Passing',
    'Shooting',
    'Dribbling',
    'Physical',
    'Defending',
    'Pace',
    'Ball Control',
    'Body Movements',
  ];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _exerciseTabController = TabController(length: _technicalAreas.length, vsync: this);
    _exerciseService = ExerciseService(Provider.of<AuthService>(context, listen: false));
    
    _loadExercises();
    _loadSchedule();
    
    _exerciseTabController.addListener(() {
      if (!_exerciseTabController.indexIsChanging) {
        setState(() {});
        _loadExercises();
      }
    });
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _exerciseTabController.dispose();
    _weeklyGoalsController.dispose();
    super.dispose();
  }

  void _loadSchedule() {
    setState(() {
      _scheduleFuture = TrainingScheduleService.getCurrentSchedule();
    });
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoadingExercises = true;
      _exerciseError = null;
    });

    try {
      // Get selected category from tab controller
      String? category;
      if (_exerciseTabController.index > 0) {
        category = _technicalAreas[_exerciseTabController.index];
      }
      
      // Load all exercises
      final allExercises = await _exerciseService.getExercises(
        category: category,
        difficulty: _selectedDifficulty == 'All Difficulties' ? null : _selectedDifficulty,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      
      // Load favorites
      final favoriteExercises = await _exerciseService.getFavorites();
      
      setState(() {
        _allExercises = allExercises;
        _favoriteExercises = favoriteExercises;
        _isLoadingExercises = false;
      });
    } catch (e) {
      setState(() {
        _exerciseError = e.toString();
        _isLoadingExercises = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0B0057),
        bottom: TabBar(
          controller: _mainTabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Exercise Library'),
            Tab(text: 'Weekly Schedule'),
          ],
        ),
      ),
      drawer: const CustomNavigationDrawer(currentPage: 'training'),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          _buildExerciseLibrary(),
          _buildWeeklySchedule(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Refresh based on current tab
          if (_mainTabController.index == 0) {
            _loadExercises();
          } else {
            _loadSchedule();
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildExerciseLibrary() {
    return Column(
      children: [
        // Category tabs
        Container(
          color: const Color(0xFF0B0057),
          child: TabBar(
            controller: _exerciseTabController,
            isScrollable: true,
            indicatorColor: const Color(0xFF02D39A),
            indicatorWeight: 3.0,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: _technicalAreas.map((area) => Tab(
              text: area,
            )).toList(),
          ),
        ),
        
        // Search and filter section
        _buildSearchAndFilter(),
        
        // Exercise list
        Expanded(
          child: _isLoadingExercises
              ? const Center(child: CircularProgressIndicator())
              : _exerciseError != null
                  ? Center(child: Text(_exerciseError!))
                  : _buildExerciseList(),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _loadExercises();
              },
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _selectedDifficulty ?? 'All Difficulties',
            items: _difficulties.map((String difficulty) {
              return DropdownMenuItem<String>(
                value: difficulty,
                child: Text(difficulty),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedDifficulty = newValue;
              });
              _loadExercises();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    final exercises = _allExercises;
    
    if (exercises.isEmpty) {
      return const Center(
        child: Text('No exercises found'),
      );
    }
    
    return ListView.builder(
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return _buildExerciseCard(exercise);
      },
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          _getExerciseIcon(exercise.category),
          color: Theme.of(context).primaryColor,
        ),
        title: Text(exercise.name),
        subtitle: Text(exercise.difficulty),
        trailing: IconButton(
          icon: Icon(
            exercise.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: exercise.isFavorite ? Colors.red : null,
          ),
          onPressed: () => _toggleFavorite(exercise),
        ),
        onTap: () => _openExerciseDetails(exercise),
      ),
    );
  }

  IconData _getExerciseIcon(String category) {
    switch (category.toLowerCase()) {
      case 'passing':
        return Icons.sports_soccer;
      case 'shooting':
        return Icons.sports_hockey;
      case 'dribbling':
        return Icons.run_circle;
      case 'physical':
        return Icons.fitness_center;
      case 'defending':
        return Icons.shield;
      case 'pace':
        return Icons.speed;
      case 'ball control':
        return Icons.sports_basketball;
      default:
        return Icons.sports_soccer;
    }
  }

  Future<void> _toggleFavorite(Exercise exercise) async {
    try {
      final updatedExercise = await _exerciseService.toggleFavorite(exercise.id);
      setState(() {
        // Update in all exercises list
        final index = _allExercises.indexWhere((e) => e.id == exercise.id);
        if (index != -1) {
          _allExercises[index] = updatedExercise;
        }
        
        // Update favorites list
        if (updatedExercise.isFavorite) {
          _favoriteExercises.add(updatedExercise);
        } else {
          _favoriteExercises.removeWhere((e) => e.id == exercise.id);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update favorite status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openExerciseDetails(Exercise exercise) {
    // Navigate to exercise details
    Navigator.pushNamed(
      context,
      '/exercise-details',
      arguments: exercise,
    );
  }

  Widget _buildWeeklySchedule() {
    return FutureBuilder<WeeklyTrainingSchedule>(
      future: _scheduleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading schedule: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }
        
        if (!snapshot.hasData) {
          return const Center(
            child: Text(
              'No schedule found',
              style: TextStyle(color: Colors.white),
            ),
          );
        }
        
        final schedule = snapshot.data!;
        return _buildScheduleContent(schedule);
      },
    );
  }

  Widget _buildScheduleContent(WeeklyTrainingSchedule schedule) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildWeekHeader(schedule),
        const SizedBox(height: 16),
        _buildWeeklyGoals(schedule),
        const SizedBox(height: 16),
        ...schedule.days.map((day) => _buildDayCard(day)),
      ],
    );
  }

  Widget _buildWeekHeader(WeeklyTrainingSchedule schedule) {
    final endDate = schedule.weekStartDate.add(const Duration(days: 6));
    final dateFormat = DateFormat('MMM d');
    
    return Card(
      color: AppColors.cardBackground.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Week of ${dateFormat.format(schedule.weekStartDate)} - ${dateFormat.format(endDate)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyGoals(WeeklyTrainingSchedule schedule) {
    return Card(
      color: AppColors.cardBackground.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Weekly Goals',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isEditingWeeklyGoals ? Icons.save : Icons.edit,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (_isEditingWeeklyGoals) {
                      _saveWeeklyGoals(schedule);
                    } else {
                      setState(() {
                        _isEditingWeeklyGoals = true;
                        _weeklyGoalsController.text = schedule.weeklyGoals ?? '';
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isEditingWeeklyGoals)
              TextField(
                controller: _weeklyGoalsController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter your goals for this week...',
                  hintStyle: TextStyle(color: Colors.white70),
                ),
              )
            else
              Text(
                schedule.weeklyGoals ?? 'No goals set for this week',
                style: const TextStyle(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(TrainingDay day) {
    return Card(
      color: AppColors.cardBackground.withOpacity(0.5),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          day.dayName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          day.description ?? 'No training scheduled',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.white,
        ),
        onTap: () {
          // Navigate to day detail
          Navigator.pushNamed(
            context,
            '/training-day',
            arguments: day,
          );
        },
      ),
    );
  }

  Future<void> _saveWeeklyGoals(WeeklyTrainingSchedule schedule) async {
    if (_weeklyGoalsController.text.isEmpty) return;
    
    try {
      final updatedSchedule = await TrainingScheduleService.updateWeeklyGoals(
        schedule, 
        _weeklyGoalsController.text,
      );
      
      setState(() {
        _isEditingWeeklyGoals = false;
        _scheduleFuture = Future.value(updatedSchedule);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save goals: $e')),
      );
    }
  }
} 