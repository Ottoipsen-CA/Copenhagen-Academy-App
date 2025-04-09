import 'package:flutter/material.dart';
import '../../models/development_plan.dart';
import '../../services/development_plan_service.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/gradient_background.dart';

class DevelopmentPlanEditorPage extends StatefulWidget {
  final DevelopmentPlan? plan;
  final DevelopmentPlanService service;

  const DevelopmentPlanEditorPage({
    Key? key,
    this.plan,
    required this.service,
  }) : super(key: key);

  @override
  _DevelopmentPlanEditorPageState createState() => _DevelopmentPlanEditorPageState();
}

class _DevelopmentPlanEditorPageState extends State<DevelopmentPlanEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final List<TrainingSession> _trainingSessions = [];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.plan?.title ?? '';
    if (widget.plan != null) {
      _trainingSessions.addAll(widget.plan!.trainingSessions);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final plan = DevelopmentPlan(
        id: widget.plan?.id,
        playerId: widget.plan?.playerId ?? 1, // TODO: Get actual player ID
        title: _titleController.text,
        trainingSessions: _trainingSessions,
      );

      if (widget.plan == null) {
        await widget.service.createDevelopmentPlan(plan);
      } else {
        await widget.service.updateDevelopmentPlan(plan);
      }

      if (mounted) {
        Navigator.pop(context, plan);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addTrainingSession() async {
    final result = await showDialog<TrainingSession>(
      context: context,
      builder: (context) => _TrainingSessionDialog(),
    );

    if (result != null) {
      setState(() {
        _trainingSessions.add(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.plan == null ? 'New Training Plan' : 'Edit Training Plan',
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePlan,
          ),
        ],
      ),
      body: GradientBackground(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Plan Title',
                  filled: true,
                  fillColor: Colors.white10,
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Training Sessions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addTrainingSession,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Session'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._trainingSessions.map((session) => _buildSessionCard(session)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(TrainingSession session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    session.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _trainingSessions.remove(session);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_getWeekdayName(session.weekday)} at ${session.startTime} (${session.durationMinutes} min)',
              style: const TextStyle(color: Colors.white70),
            ),
            if (session.description != null) ...[
              const SizedBox(height: 8),
              Text(
                session.description!,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[weekday - 1];
  }
}

class _TrainingSessionDialog extends StatefulWidget {
  @override
  _TrainingSessionDialogState createState() => _TrainingSessionDialogState();
}

class _TrainingSessionDialogState extends State<_TrainingSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _durationController = TextEditingController();
  int _selectedWeekday = 1;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startTimeController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Training Session'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedWeekday,
                decoration: const InputDecoration(
                  labelText: 'Day of Week',
                ),
                items: [
                  for (var i = 1; i <= 7; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(_getWeekdayName(i)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedWeekday = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _startTimeController,
                decoration: const InputDecoration(
                  labelText: 'Start Time (HH:MM)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a start time';
                  }
                  // TODO: Add time format validation
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a duration';
                  }
                  final duration = int.tryParse(value);
                  if (duration == null || duration <= 0) {
                    return 'Please enter a valid duration';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final session = TrainingSession(
                planId: 1, // TODO: Get actual plan ID
                title: _titleController.text,
                description: _descriptionController.text.isEmpty
                    ? null
                    : _descriptionController.text,
                date: DateTime.now(), // TODO: Calculate actual date based on weekday
                weekday: _selectedWeekday,
                startTime: _startTimeController.text,
                durationMinutes: int.parse(_durationController.text),
              );
              Navigator.pop(context, session);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  String _getWeekdayName(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[weekday - 1];
  }
} 