import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadChallenges();
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
      builder: (context) => AlertDialog(
        title: Text('Edit Challenge'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: difficultyController,
                decoration: InputDecoration(labelText: 'Difficulty'),
              ),
              TextField(
                controller: pointsController,
                decoration: InputDecoration(labelText: 'Points'),
                keyboardType: TextInputType.number,
              ),
              ListTile(
                title: Text('Start Date'),
                subtitle: Text(startDate.toString()),
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
              ),
              ListTile(
                title: Text('End Date'),
                subtitle: Text(endDate.toString()),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: endDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => endDate = date);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
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
                badgeId: null,  // Set badgeId to null instead of 0
              );

              try {
                await widget.apiService.updateChallenge(updatedChallenge);
                Navigator.pop(context);
                _loadChallenges(); // Refresh the list
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating challenge: $e')),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog() async {
    // First get the current user's ID
    final userResponse = await widget.apiService.get('/api/v2/auth/me');
    final userId = userResponse['id'];

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
        builder: (context, setState) => AlertDialog(
          title: Text('Create Challenge'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: categoryController,
                  decoration: InputDecoration(labelText: 'Category'),
                ),
                TextField(
                  controller: difficultyController,
                  decoration: InputDecoration(labelText: 'Difficulty'),
                ),
                TextField(
                  controller: pointsController,
                  decoration: InputDecoration(labelText: 'Points'),
                  keyboardType: TextInputType.number,
                ),
                ListTile(
                  title: Text('Start Date'),
                  subtitle: Text(startDate?.toString() ?? 'Not set'),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() => startDate = date);
                    }
                  },
                ),
                ListTile(
                  title: Text('End Date'),
                  subtitle: Text(endDate?.toString() ?? 'Not set'),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() => endDate = date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (startDate != null && endDate != null) {
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
                    'created_by': userId,  // Add the current user's ID
                  };

                  try {
                    await widget.apiService.post('/api/v2/challenges/', challenge);
                    Navigator.pop(context);
                    _loadChallenges(); // Refresh the list
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating challenge: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select both start and end dates')),
                  );
                }
              },
              child: Text('Create'),
            ),
          ],
        ),
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
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Manage Challenges',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: _showCreateDialog,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _challenges.length,
            itemBuilder: (context, index) {
              final challenge = _challenges[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  title: Text(challenge.title),
                  subtitle: Text(
                    'Points: ${challenge.points} | Category: ${challenge.category} | Difficulty: ${challenge.difficulty}\n'
                    '${challenge.startDate.toString().split(' ')[0]} - ${challenge.endDate.toString().split(' ')[0]}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _showEditDialog(challenge),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
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