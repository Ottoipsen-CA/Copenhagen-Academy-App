import 'package:flutter/material.dart';
import '../../models/development_plan.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/navigation_drawer.dart';

class SessionDetailsPage extends StatefulWidget {
  final TrainingSession session;
  final Function(TrainingSession) onSave;

  const SessionDetailsPage({
    Key? key,
    required this.session,
    required this.onSave,
  }) : super(key: key);

  @override
  _SessionDetailsPageState createState() => _SessionDetailsPageState();
}

class _SessionDetailsPageState extends State<SessionDetailsPage> {
  late TextEditingController _notesController;
  bool _isEditing = false;
  bool _isMatch = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.session.description);
    _isMatch = widget.session.title.toLowerCase().contains('match');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomNavigationDrawer(currentPage: 'developmentPlan'),
      appBar: CustomAppBar(
        title: widget.session.title,
        hasBackButton: true,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                final updatedSession = TrainingSession(
                  sessionId: widget.session.sessionId,
                  planId: widget.session.planId,
                  title: widget.session.title,
                  description: _notesController.text,
                  date: widget.session.date,
                  weekday: widget.session.weekday,
                  startTime: widget.session.startTime,
                  durationMinutes: widget.session.durationMinutes,
                  preEvaluation: widget.session.preEvaluation,
                  postEvaluation: widget.session.postEvaluation,
                  isCompleted: widget.session.isCompleted,
                );
                widget.onSave(updatedSession);
              }
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: GradientBackground(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session Info Card
          Card(
            color: AppColors.cardBackground,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isMatch ? Icons.sports_soccer : Icons.fitness_center,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isMatch ? 'Match Details' : 'Training Details',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Time', widget.session.startTime),
                  _buildInfoRow(
                    'Duration',
                    '${widget.session.durationMinutes} minutes',
                  ),
                  _buildInfoRow(
                    'Status',
                    widget.session.isCompleted ? 'Completed' : 'Upcoming',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Notes Section
          const Text(
            'Notes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: AppColors.cardBackground,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _isEditing
                  ? TextFormField(
                      controller: _notesController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Add your notes here...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                      ),
                      maxLines: 5,
                    )
                  : Text(
                      widget.session.description ?? 'No notes added yet',
                      style: TextStyle(
                        color:
                            widget.session.description != null ? Colors.white : Colors.white54,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Evaluations Section
          const Text(
            'Evaluations',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildEvaluationCard(
                  'Pre-Training',
                  widget.session.preEvaluation,
                  () => _addEvaluation(true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEvaluationCard(
                  'Post-Training',
                  widget.session.postEvaluation,
                  () => _addEvaluation(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationCard(
    String title,
    SessionEvaluation? evaluation,
    VoidCallback onAdd,
  ) {
    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (evaluation == null)
              Center(
                child: TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Evaluation'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < evaluation.rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    evaluation.notes,
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(evaluation.createdAt),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () => _deleteEvaluation(evaluation == widget.session.preEvaluation),
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

  Future<void> _addEvaluation(bool isPre) async {
    final result = await showDialog<SessionEvaluation>(
      context: context,
      builder: (context) => _EvaluationDialog(
        sessionId: widget.session.sessionId ?? 1,
        isPostEvaluation: !isPre,
      ),
    );

    if (result != null) {
      final updatedSession = TrainingSession(
        sessionId: widget.session.sessionId,
        planId: widget.session.planId,
        title: widget.session.title,
        description: widget.session.description,
        date: widget.session.date,
        weekday: widget.session.weekday,
        startTime: widget.session.startTime,
        durationMinutes: widget.session.durationMinutes,
        preEvaluation: isPre ? result : widget.session.preEvaluation,
        postEvaluation: isPre ? widget.session.postEvaluation : result,
        isCompleted: widget.session.isCompleted,
      );
      widget.onSave(updatedSession);
    }
  }

  void _deleteEvaluation(bool isPre) {
    final updatedSession = TrainingSession(
      sessionId: widget.session.sessionId,
      planId: widget.session.planId,
      title: widget.session.title,
      description: widget.session.description,
      date: widget.session.date,
      weekday: widget.session.weekday,
      startTime: widget.session.startTime,
      durationMinutes: widget.session.durationMinutes,
      preEvaluation: isPre ? null : widget.session.preEvaluation,
      postEvaluation: isPre ? widget.session.postEvaluation : null,
      isCompleted: widget.session.isCompleted,
    );
    widget.onSave(updatedSession);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _EvaluationDialog extends StatefulWidget {
  final int sessionId;
  final bool isPostEvaluation;

  const _EvaluationDialog({
    Key? key,
    required this.sessionId,
    required this.isPostEvaluation,
  }) : super(key: key);

  @override
  _EvaluationDialogState createState() => _EvaluationDialogState();
}

class _EvaluationDialogState extends State<_EvaluationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  int _rating = 0;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Evaluation'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isPostEvaluation) ...[
                const Text(
                  'Rate your performance:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          _rating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some notes';
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
            if (_formKey.currentState!.validate() && (!widget.isPostEvaluation || _rating > 0)) {
              final evaluation = SessionEvaluation(
                sessionId: widget.sessionId,
                notes: _notesController.text,
                rating: widget.isPostEvaluation ? _rating : 0,
                createdAt: DateTime.now(),
              );
              Navigator.pop(context, evaluation);
            } else if (widget.isPostEvaluation && _rating == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select a rating'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
} 