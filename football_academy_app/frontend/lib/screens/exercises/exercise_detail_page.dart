import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../models/exercise.dart';
import '../../services/exercise_service.dart';
import '../../services/auth_service.dart';

class ExerciseDetailPage extends StatefulWidget {
  final int exerciseId;

  const ExerciseDetailPage({
    Key? key,
    required this.exerciseId,
  }) : super(key: key);

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {
  late ExerciseService _exerciseService;
  Exercise? _exercise;
  bool _isLoading = true;
  String? _errorMessage;
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    _exerciseService = ExerciseService(Provider.of<AuthService>(context, listen: false));
    _loadExercise();
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  Future<void> _loadExercise() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final exercise = await _exerciseService.getExercise(widget.exerciseId);
      
      // Initialize YouTube player if video URL exists
      if (exercise.videoUrl != null && exercise.videoUrl!.contains('youtube')) {
        final videoId = YoutubePlayer.convertUrlToId(exercise.videoUrl!);
        if (videoId != null) {
          _youtubeController = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
            ),
          );
        }
      }
      
      setState(() {
        _exercise = exercise;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_exercise == null) return;

    try {
      final updatedExercise = await _exerciseService.toggleFavorite(_getExerciseNumericId(_exercise!.id));
      setState(() {
        _exercise = updatedExercise;
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
        title: Text(_exercise?.title ?? 'Exercise Details'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0B0057),
        actions: [
          if (_exercise != null)
            IconButton(
              icon: Icon(
                _exercise!.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _exercise!.isFavorite ? Colors.red : Colors.white,
              ),
              onPressed: _toggleFavorite,
            ),
        ],
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
                : _exercise == null
                    ? const Center(
                        child: Text(
                          'Exercise not found',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : _buildExerciseDetails(),
      ),
    );
  }

  Widget _buildExerciseDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise header
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    _exercise!.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Category and difficulty
                  Row(
                    children: [
                      _buildInfoChip(
                        label: _exercise!.category,
                        icon: Icons.category,
                        color: _getCategoryColor(_exercise!.category),
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        label: _exercise!.difficulty,
                        icon: Icons.trending_up,
                        color: _getDifficultyColor(_exercise!.difficulty),
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        label: '${_exercise!.durationMinutes} min',
                        icon: Icons.timer,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Video player
          if (_youtubeController != null)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Video Demonstration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: YoutubePlayer(
                        controller: _youtubeController!,
                        showVideoProgressIndicator: true,
                        progressIndicatorColor: Theme.of(context).primaryColor,
                        progressColors: const ProgressBarColors(
                          playedColor: Colors.red,
                          handleColor: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_exercise!.imageUrl != null)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Exercise Image',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _exercise!.imageUrl!,
                        fit: BoxFit.cover,
                        height: 200,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.image_not_supported, size: 50),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          
          // Description
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _exercise!.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Equipment needed
          if (_exercise!.equipment != null && _exercise!.equipment!.isNotEmpty)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Equipment Needed',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _exercise!.equipment!
                          .map((item) => Chip(
                                label: Text(item),
                                avatar: const Icon(Icons.sports_soccer),
                                backgroundColor: Colors.grey[200],
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          
          // Skills improved
          if (_exercise!.skills != null && _exercise!.skills!.isNotEmpty)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Skills Improved',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _exercise!.skills!
                          .map((skill) => Chip(
                                label: Text(skill),
                                avatar: const Icon(Icons.fitness_center),
                                backgroundColor: Colors.blue[100],
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          
          // Created by
          if (_exercise!.createdBy != null && _exercise!.createdAt != null)
            Center(
              child: Text(
                'Added by ${_exercise!.createdBy} on ${_formatDate(_exercise!.createdAt!)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
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
        return Colors.red;
      case 'Fitness':
        return Colors.purple;
      case 'Ball Control':
        return Colors.teal;
      case 'Attacking':
        return Colors.amber;
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

  String _formatDate(DateTime dateTime) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }
} 