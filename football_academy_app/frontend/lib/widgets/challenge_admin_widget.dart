import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/challenge_admin.dart';
import '../services/api_service.dart';

class ChallengeAdminWidget extends StatefulWidget {
  final ApiService apiService;

  const ChallengeAdminWidget({
    Key? key,
    required this.apiService,
  }) : super(key: key);

  @override
  _ChallengeAdminWidgetState createState() => _ChallengeAdminWidgetState();
}

class _ChallengeAdminWidgetState extends State<ChallengeAdminWidget> {
  List<ChallengeAdmin> _challenges = [];
  bool _isLoading = true;
  int? _selectedWeeklyChallengeId;

  @override
  void initState() {
    super.initState();
    _loadSelectedWeeklyChallengeId();
    _loadChallenges();
  }

  Future<void> _loadSelectedWeeklyChallengeId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedWeeklyChallengeId = prefs.getInt('current_weekly_challenge_id');
    });
  }

  Future<void> _setSelectedWeeklyChallengeId(int challengeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_weekly_challenge_id', challengeId);
    setState(() {
      _selectedWeeklyChallengeId = challengeId;
    });
  }

  Future<void> _loadChallenges() async {
    setState(() => _isLoading = true);
    try {
      final response = await widget.apiService.get('/api/v2/challenges/');
      setState(() {
        _challenges = (response as List)
            .map((json) => ChallengeAdmin.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading challenges: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd-MM-yy').format(date);
  }

  Future<void> _showEditDialog(ChallengeAdmin challenge) async {
    final titleController = TextEditingController(text: challenge.title);
    final descriptionController = TextEditingController(text: challenge.description);
    final categoryController = TextEditingController(text: challenge.category);
    final difficultyController = TextEditingController(text: challenge.difficulty);
    final pointsController = TextEditingController(text: challenge.points.toString());
    DateTime startDate = challenge.startDate;
    DateTime endDate = challenge.endDate;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Edit Challenge'),
                automaticallyImplyLeading: false,
                backgroundColor: Colors.black.withOpacity(0.3),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
              ),
                      const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
              ),
                      const SizedBox(height: 16),
              TextField(
                controller: difficultyController,
                        decoration: const InputDecoration(
                          labelText: 'Difficulty',
                          border: OutlineInputBorder(),
                        ),
              ),
                      const SizedBox(height: 16),
              TextField(
                controller: pointsController,
                        decoration: const InputDecoration(
                          labelText: 'Points',
                          border: OutlineInputBorder(),
                        ),
                keyboardType: TextInputType.number,
              ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Start Date',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => startDate = date);
                  }
                },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      _formatDate(startDate),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'End Date',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: endDate,
                                      firstDate: startDate,
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => endDate = date);
                  }
                },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      _formatDate(endDate),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
              ),
            ],
          ),
        ),
              ),
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
          ),
                    const SizedBox(width: 8),
                    ElevatedButton(
            onPressed: () async {
              final updatedChallenge = ChallengeAdmin(
                id: challenge.id,
                title: titleController.text,
                description: descriptionController.text,
                category: categoryController.text,
                difficulty: difficultyController.text,
                points: int.tryParse(pointsController.text) ?? 0,
                criteria: challenge.criteria,
                startDate: startDate,
                endDate: endDate,
                isActive: challenge.isActive,
                createdBy: challenge.createdBy,
                          badgeId: null,
              );

              try {
                await widget.apiService.updateChallenge(updatedChallenge);
                Navigator.pop(context);
                          _loadChallenges();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating challenge: $e')),
                );
              }
            },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController();
    final difficultyController = TextEditingController();
    final pointsController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBar(
                    title: const Text('Create Challenge'),
                    automaticallyImplyLeading: false,
                    backgroundColor: Colors.black.withOpacity(0.3),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              border: OutlineInputBorder(),
                            ),
                ),
                          const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                TextField(
                  controller: categoryController,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                ),
                          const SizedBox(height: 16),
                TextField(
                  controller: difficultyController,
                            decoration: const InputDecoration(
                              labelText: 'Difficulty',
                              border: OutlineInputBorder(),
                            ),
                ),
                          const SizedBox(height: 16),
                TextField(
                  controller: pointsController,
                            decoration: const InputDecoration(
                              labelText: 'Points',
                              border: OutlineInputBorder(),
                            ),
                  keyboardType: TextInputType.number,
                ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Start Date',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                                          setDialogState(() => startDate = date);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Text(
                                          startDate != null ? _formatDate(startDate!) : 'Not set',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'End Date',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                                          firstDate: startDate ?? DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                                          setDialogState(() => endDate = date);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Text(
                                          endDate != null ? _formatDate(endDate!) : 'Not set',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                ),
              ],
            ),
          ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
            ),
                        const SizedBox(width: 8),
                        ElevatedButton(
              onPressed: () async {
                if (startDate != null && endDate != null) {
                              final userResponse = await widget.apiService.get('/api/v2/auth/me');
                              final userId = userResponse['id'];
                              
                  final challenge = {
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'category': categoryController.text,
                    'difficulty': difficultyController.text,
                    'points': int.tryParse(pointsController.text) ?? 0,
                    'criteria': {},
                    'start_date': startDate!.toIso8601String(),
                    'end_date': endDate!.toIso8601String(),
                    'is_active': true,
                    'badge_id': null,
                                'created_by': userId,
                  };

                  try {
                    await widget.apiService.post('/api/v2/challenges/', challenge);
                    Navigator.pop(context);
                                _loadChallenges();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating challenge: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select both start and end dates')),
                  );
                }
              },
                          child: const Text('Create'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteChallenge(ChallengeAdmin challenge) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Challenge'),
        content: Text('Are you sure you want to delete this challenge?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.apiService.delete('/api/v2/challenges/${challenge.id}');
        _loadChallenges(); // Refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting challenge: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Manage Challenges',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 28),
                onPressed: _showCreateDialog,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _challenges.length,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            itemBuilder: (context, index) {
              final challenge = _challenges[index];
              final isSelectedWeekly = challenge.id == _selectedWeeklyChallengeId;

              return Container(
                margin: const EdgeInsets.only(bottom: 12.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelectedWeekly ? Border.all(color: Colors.amber, width: 2) : null,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  title: Text(
                    challenge.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Points: ${challenge.points} | Category: ${challenge.category} | Difficulty: ${challenge.difficulty}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Date',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _formatDate(challenge.startDate),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End Date',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _formatDate(challenge.endDate),
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
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isSelectedWeekly ? Icons.star : Icons.star_border,
                          color: isSelectedWeekly ? Colors.amber : Colors.white.withOpacity(0.7),
                        ),
                        tooltip: 'Set as Weekly Challenge',
                        onPressed: () {
                          _setSelectedWeeklyChallengeId(challenge.id);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () => _showEditDialog(challenge),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: () => _deleteChallenge(challenge),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
} 