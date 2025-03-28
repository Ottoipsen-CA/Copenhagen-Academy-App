import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/exercise.dart';
import '../../services/exercise_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/navigation_drawer.dart';
import 'exercise_detail_page.dart';

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _categoriesTabController;
  late ExerciseService _exerciseService;
  
  List<Exercise> _allExercises = [];
  List<Exercise> _favoriteExercises = [];
  bool _isLoading = true;
  String? _errorMessage;
  
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
    _categoriesTabController = TabController(length: _technicalAreas.length, vsync: this);
    _exerciseService = ExerciseService(Provider.of<AuthService>(context, listen: false));
    _loadExercises();
    
    _categoriesTabController.addListener(() {
      if (!_categoriesTabController.indexIsChanging) {
        setState(() {});
        _loadExercises();
      }
    });
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _categoriesTabController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get selected category from tab controller
      String? category;
      if (_categoriesTabController.index > 0) {
        category = _technicalAreas[_categoriesTabController.index];
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(Exercise exercise) async {
    try {
      final updatedExercise = await _exerciseService.toggleFavorite(_getExerciseNumericId(exercise.id));
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

  void _applyFilters() {
    _loadExercises();
  }

  void _resetFilters() {
    setState(() {
      _selectedDifficulty = null;
      _searchQuery = '';
    });
    _loadExercises();
  }

  // Helper method to convert string IDs to integers
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0B0057),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main tabs (All Exercises/Favorites)
              TabBar(
                controller: _mainTabController,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'All Exercises'),
                  Tab(text: 'Favorites'),
                ],
              ),
              // Category tabs (scrollable)
              SizedBox(
                height: 40,
                child: TabBar(
                  controller: _categoriesTabController,
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
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterBottomSheet();
            },
          ),
        ],
      ),
      drawer: const CustomNavigationDrawer(currentPage: 'exercises'),
      body: Container(
        decoration: const BoxDecoration(
          // Space-themed background with stars
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
                : _buildTabContent(),
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _mainTabController,
      children: [
        // All Exercises Tab
        _buildExerciseGrid(_getFilteredExercises(_allExercises)),
        
        // Favorites Tab
        _favoriteExercises.isEmpty
            ? const Center(
                child: Text(
                  'No favorite exercises yet!',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              )
            : _buildExerciseGrid(_getFilteredExercises(_favoriteExercises)),
      ],
    );
  }
  
  List<Exercise> _getFilteredExercises(List<Exercise> exercises) {
    // If "All" is selected (index 0), return all exercises
    if (_categoriesTabController.index == 0) {
      return exercises;
    }
    
    // Otherwise filter by the selected category
    final category = _technicalAreas[_categoriesTabController.index];
    return exercises.where((e) => e.category == category).toList();
  }

  Widget _buildExerciseGrid(List<Exercise> exercises) {
    return exercises.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.sports_soccer_outlined,
                  color: Colors.white54,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${_categoriesTabController.index > 0 ? _technicalAreas[_categoriesTabController.index] : ""} exercises found!',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadExercises,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 12,
                ),
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  return _buildExerciseCard(exercise);
                },
              ),
            ),
          );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseDetailPage(exerciseId: _getExerciseNumericId(exercise.id)),
          ),
        ).then((_) => _loadExercises()); // Refresh after returning from detail page
      },
      child: Card(
        elevation: 3,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise image
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Image.network(
                    exercise.imageUrl ?? 'https://via.placeholder.com/300x200?text=No+Image',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 24),
                        ),
                      );
                    },
                  ),
                ),
                // Exercise info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // Category and difficulty
                        Wrap(
                          spacing: 2,
                          children: [
                            _buildDifficultyChip(exercise.difficulty),
                            if (exercise.videoUrl != null)
                              _buildVideoChip(),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Duration
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, size: 10, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text(
                              '${exercise.durationMinutes} min',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Favorite button
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: () => _toggleFavorite(exercise),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    exercise.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: exercise.isFavorite ? Colors.red : Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.play_circle_outline, size: 8, color: Colors.red),
          SizedBox(width: 2),
          Text(
            'Video',
            style: TextStyle(
              fontSize: 8,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(String difficulty) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: _getDifficultyColor(difficulty).withOpacity(0.2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          fontSize: 8,
          color: _getDifficultyColor(difficulty),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Dribbling':
        return Colors.blue;
      case 'Passing':
        return Colors.green;
      case 'Shooting':
        return Colors.orange;
      case 'Defense':
      case 'Defending':
        return Colors.red;
      case 'Fitness':
      case 'Physical':
        return Colors.purple;
      case 'Ball Control':
        return Colors.teal;
      case 'Attacking':
      case 'Pace':
        return Colors.amber;
      case 'Body Movements':
        return Colors.indigo;
      default:
        return Colors.blueGrey;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Beginner':
        return Colors.green;
      case 'Intermediate':
        return Colors.orange;
      case 'Advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showFilterBottomSheet() {
    // Create a text controller with the current search query
    final searchController = TextEditingController(text: _searchQuery);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Wrap(
                children: [
                  const Text(
                    'Filter Exercises',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Search input
                  const Text('Search'),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search exercises...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Difficulty dropdown
                  const Text('Difficulty'),
                  DropdownButtonFormField<String>(
                    value: _selectedDifficulty ?? 'All Difficulties',
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: _difficulties.map((difficulty) {
                      return DropdownMenuItem(
                        value: difficulty,
                        child: Text(difficulty),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDifficulty = value == 'All Difficulties' ? null : value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _resetFilters();
                        },
                        child: const Text('Reset'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Apply Filters'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
} 