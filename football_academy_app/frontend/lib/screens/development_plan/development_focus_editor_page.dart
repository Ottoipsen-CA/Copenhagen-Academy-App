import 'package:flutter/material.dart';
import '../../models/development_plan.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/navigation_drawer.dart';

class DevelopmentFocusEditorPage extends StatefulWidget {
  final DevelopmentPlan plan;
  final Function(DevelopmentPlan) onSave;

  const DevelopmentFocusEditorPage({
    Key? key,
    required this.plan,
    required this.onSave,
  }) : super(key: key);

  @override
  _DevelopmentFocusEditorPageState createState() => _DevelopmentFocusEditorPageState();
}

class _DevelopmentFocusEditorPageState extends State<DevelopmentFocusEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _longTermGoalsController = TextEditingController();
  final _notesController = TextEditingController();
  late List<FocusArea> _focusAreas;

  @override
  void initState() {
    super.initState();
    _longTermGoalsController.text = widget.plan.longTermGoals ?? '';
    _notesController.text = widget.plan.notes ?? '';
    _focusAreas = List.from(widget.plan.focusAreas);
  }

  @override
  void dispose() {
    _longTermGoalsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedPlan = DevelopmentPlan(
      id: widget.plan.id,
      playerId: widget.plan.playerId,
      title: widget.plan.title,
      trainingSessions: widget.plan.trainingSessions,
      focusAreas: _focusAreas,
      longTermGoals: _longTermGoalsController.text.isEmpty ? null : _longTermGoalsController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    widget.onSave(updatedPlan);
    Navigator.pop(context);
  }

  void _addFocusArea() {
    showDialog<FocusArea>(
      context: context,
      builder: (context) => _FocusAreaDialog(),
    ).then((area) {
      if (area != null) {
        setState(() {
          _focusAreas.add(area);
        });
      }
    });
  }

  void _editFocusArea(int index) {
    showDialog<FocusArea>(
      context: context,
      builder: (context) => _FocusAreaDialog(focusArea: _focusAreas[index]),
    ).then((area) {
      if (area != null) {
        setState(() {
          _focusAreas[index] = area;
        });
      }
    });
  }

  void _removeFocusArea(int index) {
    setState(() {
      _focusAreas.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomNavigationDrawer(currentPage: 'developmentPlan'),
      appBar: CustomAppBar(
        title: 'Rediger Udviklingsfokus',
        hasBackButton: true,
      ),
      body: GradientBackground(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Long-Term Goals',
            child: TextFormField(
              controller: _longTermGoalsController,
              decoration: const InputDecoration(
                hintText: 'Enter your long-term goals',
                filled: true,
                fillColor: Colors.white10,
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
            ),
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Focus Areas',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_focusAreas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No focus areas defined',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                else
                  ...List.generate(
                    _focusAreas.length,
                    (index) => _buildFocusAreaItem(index),
                  ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _addFocusArea,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Focus Area'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Notes',
            child: TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Enter any additional notes',
                filled: true,
                fillColor: Colors.white10,
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _savePlan,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildFocusAreaItem(int index) {
    final area = _focusAreas[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.cardBackground.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    area.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white70),
                      onPressed: () => _editFocusArea(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeFocusArea(index),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              area.description,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Target: ${_formatDate(area.targetDate)}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _FocusAreaDialog extends StatefulWidget {
  final FocusArea? focusArea;

  const _FocusAreaDialog({Key? key, this.focusArea}) : super(key: key);

  @override
  _FocusAreaDialogState createState() => _FocusAreaDialogState();
}

class _FocusAreaDialogState extends State<_FocusAreaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late DateTime _targetDate;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.focusArea?.title ?? '';
    _descriptionController.text = widget.focusArea?.description ?? '';
    _targetDate = widget.focusArea?.targetDate ?? DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _targetDate) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.focusArea == null ? 'Add Focus Area' : 'Edit Focus Area'),
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
                  border: OutlineInputBorder(),
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
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Target Date'),
                subtitle: Text(_formatDate(_targetDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
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
              final area = FocusArea(
                id: widget.focusArea?.id,
                title: _titleController.text,
                description: _descriptionController.text,
                priority: widget.focusArea?.priority ?? 3,
                targetDate: _targetDate,
                isCompleted: widget.focusArea?.isCompleted ?? false,
              );
              Navigator.pop(context, area);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 