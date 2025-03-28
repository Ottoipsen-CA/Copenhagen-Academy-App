import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/training_plan.dart';
import '../../models/player_stats.dart';
import '../../services/auth_service.dart';
import '../../services/exercise_service.dart';
import '../../services/training_plan_service.dart';
import 'training_plan_detail_page.dart';

class CreateTrainingPlanPage extends StatefulWidget {
  const CreateTrainingPlanPage({super.key});

  @override
  State<CreateTrainingPlanPage> createState() => _CreateTrainingPlanPageState();
}

class _CreateTrainingPlanPageState extends State<CreateTrainingPlanPage> {
  final _formKey = GlobalKey<FormState>();
  
  String _selectedFocusArea = 'Shooting';
  String _selectedLevel = 'Intermediate';
  int _selectedDuration = 6;
  String _goalDescription = '';
  bool _isLoading = false;
  String? _userName;
  
  // Available options
  final List<String> _focusAreas = [
    'Shooting',
    'Passing',
    'Dribbling',
    'Defending',
    'Physical',
    'Ball Control',
    'Pace',
  ];
  
  final List<String> _playerLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];
  
  final List<int> _durations = [4, 6, 8, 12];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.getCurrentUser();
      setState(() {
        _userName = user.fullName.split(' ')[0];
      });
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Training Plan'),
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
            : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.fitness_center,
                    size: 64,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName != null
                        ? 'Hey $_userName, let\'s create your training plan!'
                        : 'Let\'s create your training plan!',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your personalized plan will adapt to your level and progressively increase in difficulty.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Focus Area Section
            const Text(
              'What do you want to improve?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Focus Area Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _focusAreas.length,
              itemBuilder: (context, index) {
                final focusArea = _focusAreas[index];
                final isSelected = _selectedFocusArea == focusArea;
                
                return _buildFocusAreaItem(focusArea, isSelected);
              },
            ),
            
            const SizedBox(height: 32),
            
            // Skill Level Section
            const Text(
              'Your current skill level',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Skill Level Selection
            Row(
              children: _playerLevels.map((level) {
                final isSelected = _selectedLevel == level;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildLevelButton(level, isSelected),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 32),
            
            // Duration Section
            const Text(
              'Program Duration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Duration Selector
            Column(
              children: [
                Text(
                  '$_selectedDuration weeks',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.orange,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.orange,
                    overlayColor: Colors.orange.withOpacity(0.2),
                    valueIndicatorColor: Colors.orange,
                    showValueIndicator: ShowValueIndicator.always,
                  ),
                  child: Slider(
                    min: 4,
                    max: 12,
                    divisions: 4,
                    value: _selectedDuration.toDouble(),
                    label: '$_selectedDuration weeks',
                    onChanged: (value) {
                      setState(() {
                        _selectedDuration = value.round();
                      });
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '4 weeks',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const Text(
                      '12 weeks',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Goal Description
            const Text(
              'Your goal (optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Describe what you want to achieve with this training plan',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                hintText: _userName != null 
                    ? 'E.g., $_userName wants to improve shooting accuracy with both feet...'
                    : 'E.g., I want to improve shooting accuracy with both feet...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              onChanged: (value) {
                setState(() {
                  _goalDescription = value;
                });
              },
            ),
            
            const SizedBox(height: 40),
            
            // Generate Button
            Center(
              child: ElevatedButton(
                onPressed: _generateTrainingPlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size(200, 50),
                ),
                child: const Text(
                  'Generate My Plan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusAreaItem(String focusArea, bool isSelected) {
    // Get appropriate icon and color
    IconData icon;
    Color color;
    
    switch (focusArea.toLowerCase()) {
      case 'shooting':
        icon = Icons.sports_soccer;
        color = Colors.orange;
        break;
      case 'passing':
        icon = Icons.swap_horiz;
        color = Colors.green;
        break;
      case 'dribbling':
        icon = Icons.move_down;
        color = Colors.blue;
        break;
      case 'defending':
        icon = Icons.shield;
        color = Colors.red;
        break;
      case 'physical':
        icon = Icons.fitness_center;
        color = Colors.purple;
        break;
      case 'ball control':
        icon = Icons.sports_handball;
        color = Colors.teal;
        break;
      case 'pace':
        icon = Icons.speed;
        color = Colors.amber;
        break;
      default:
        icon = Icons.sports;
        color = Colors.blueGrey;
    }
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFocusArea = focusArea;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.white.withOpacity(0.7),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              focusArea,
              style: TextStyle(
                color: isSelected ? color : Colors.white.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelButton(String level, bool isSelected) {
    Color color;
    
    switch (level.toLowerCase()) {
      case 'beginner':
        color = Colors.green;
        break;
      case 'intermediate':
        color = Colors.orange;
        break;
      case 'advanced':
        color = Colors.red;
        break;
      default:
        color = Colors.blueGrey;
    }
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedLevel = level;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? color : Colors.white.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              level,
              style: TextStyle(
                color: isSelected ? color : Colors.white.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateTrainingPlan() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final exerciseService = ExerciseService(authService);
        final trainingPlanService = TrainingPlanService(authService, exerciseService);
        
        // Get user data
        final user = await authService.getCurrentUser();
        
        // TODO: Load player stats from API
        // For now, use sample stats
        final playerStats = PlayerStats(
          playerId: int.parse(user.id!),
          pace: 75,
          shooting: 68,
          passing: 72,
          dribbling: 80,
          defense: 60,
          physical: 65,
          overallRating: 70,
        );
        
        // Generate the plan
        final trainingPlan = await trainingPlanService.generateTrainingPlan(
          focusArea: _selectedFocusArea,
          durationWeeks: _selectedDuration,
          playerLevel: _selectedLevel,
          goalDescription: _goalDescription,
          user: user,
          playerStats: playerStats,
        );
        
        // Navigate to the plan detail page
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TrainingPlanDetailPage(planId: trainingPlan.id),
            ),
          );
        }
      } catch (e) {
        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating training plan: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
} 