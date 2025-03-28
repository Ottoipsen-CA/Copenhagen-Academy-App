import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/exercise.dart';
import '../../services/auth_service.dart';
import '../../services/exercise_service.dart';

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
  
  bool _isLoading = true;
  bool _isFavoriteLoading = false;
  String? _errorMessage;
  Exercise? _exercise;

  @override
  void initState() {
    super.initState();
    
    // Initialize services
    final authService = Provider.of<AuthService>(context, listen: false);
    _exerciseService = ExerciseService(authService);
    
    _loadExercise();
  }

  Future<void> _loadExercise() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final exercise = await _exerciseService.getExercise(widget.exerciseId);
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
    if (_exercise == null || _isFavoriteLoading) return;
    
    setState(() {
      _isFavoriteLoading = true;
    });

    try {
      final updatedExercise = await _exerciseService.toggleFavorite(widget.exerciseId);
      setState(() {
        _exercise = updatedExercise;
        _isFavoriteLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating favorite: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isFavoriteLoading = false;
        });
      }
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
              onPressed: _isFavoriteLoading ? null : _toggleFavorite,
              icon: _isFavoriteLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      _exercise!.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _exercise!.isFavorite ? Colors.red : Colors.white,
                    ),
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
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error: $_errorMessage',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                : _buildExerciseDetails(),
      ),
    );
  }

  Widget _buildExerciseDetails() {
    if (_exercise == null) return Container();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise image
          if (_exercise!.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _exercise!.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey.shade800,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  );
                },
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Title
          Text(
            _exercise!.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Category and difficulty
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _exercise!.category,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _exercise!.difficulty,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_exercise!.durationMinutes} min',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Description
          const Text(
            'Description',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _exercise!.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Equipment
          if (_exercise!.equipment != null && _exercise!.equipment!.isNotEmpty) ...[
            const Text(
              'Equipment Needed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _exercise!.equipment!.map((item) {
                return Chip(
                  label: Text(item),
                  backgroundColor: Colors.purple.withOpacity(0.2),
                  labelStyle: const TextStyle(color: Colors.white),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          
          // Skills
          if (_exercise!.skills != null && _exercise!.skills!.isNotEmpty) ...[
            const Text(
              'Skills Improved',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _exercise!.skills!.map((skill) {
                return Chip(
                  label: Text(skill),
                  backgroundColor: Colors.blue.withOpacity(0.2),
                  labelStyle: const TextStyle(color: Colors.white),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
} 