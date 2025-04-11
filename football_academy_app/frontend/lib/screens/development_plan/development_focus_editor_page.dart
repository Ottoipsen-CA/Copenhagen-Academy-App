import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/development_plan.dart';
import '../../repositories/development_plan_repository.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/navigation_drawer.dart';

class DevelopmentFocusEditorPage extends StatefulWidget {
  final FocusArea? focusArea;
  final int planId;
  final DevelopmentPlanRepository repository;
  final bool isCreating;

  const DevelopmentFocusEditorPage({
    Key? key,
    this.focusArea,
    required this.planId,
    required this.repository,
    required this.isCreating,
  }) : super(key: key);

  @override
  _DevelopmentFocusEditorPageState createState() => _DevelopmentFocusEditorPageState();
}

class _DevelopmentFocusEditorPageState extends State<DevelopmentFocusEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _targetDate;
  int _priority = 3;
  String _status = 'in_progress';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.focusArea?.title ?? '');
    _descriptionController = TextEditingController(text: widget.focusArea?.description ?? '');
    _targetDate = widget.focusArea?.targetDate ?? DateTime.now().add(const Duration(days: 30));
    _priority = widget.focusArea?.priority ?? 3;
    _status = widget.focusArea?.status ?? 'in_progress';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveFocusArea() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.isCreating) {
        // Create new focus area
        final newFocusArea = FocusArea(
          developmentPlanId: widget.planId,
          title: _titleController.text,
          description: _descriptionController.text,
          priority: _priority,
          targetDate: _targetDate,
          status: _status,
        );

        await widget.repository.createFocusArea(newFocusArea);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Focus area created successfully')),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Update existing focus area
        final updatedFocusArea = FocusArea(
          focusAreaId: widget.focusArea!.focusAreaId,
          developmentPlanId: widget.planId,
          title: _titleController.text,
          description: _descriptionController.text,
          priority: _priority,
          targetDate: _targetDate,
          isCompleted: _status == 'completed',
          status: _status,
        );

        await widget.repository.updateFocusArea(updatedFocusArea);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Focus area updated successfully')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      print('Error saving focus area: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  bool _validateInputs() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return false;
    }
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return false;
    }
    return true;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.cardBackground,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppColors.cardBackground,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _targetDate) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          widget.isCreating ? 'Add Focus Area' : 'Edit Focus Area',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _saveFocusArea,
              tooltip: 'Save Focus Area',
            ),
        ],
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'Enter a title for this focus area',
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Describe what you want to achieve in this area',
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              _buildPrioritySelector(),
              const SizedBox(height: 24),
              _buildDateSelector(),
              const SizedBox(height: 24),
              _buildStatusSelector(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text('Low', style: TextStyle(color: Colors.white)),
              Expanded(
                child: Slider(
                  value: _priority.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: AppColors.primary,
                  inactiveColor: Colors.white24,
                  onChanged: (value) {
                    setState(() {
                      _priority = value.round();
                    });
                  },
                ),
              ),
              const Text('High', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Target Date',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(_targetDate),
                  style: const TextStyle(color: Colors.white),
                ),
                const Icon(
                  Icons.calendar_today,
                  color: Colors.white70,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _status,
              isExpanded: true,
              dropdownColor: AppColors.cardBackground,
              style: const TextStyle(color: Colors.white),
              iconEnabledColor: Colors.white,
              items: const [
                DropdownMenuItem(
                  value: 'not_started',
                  child: Text('Not Started'),
                ),
                DropdownMenuItem(
                  value: 'in_progress',
                  child: Text('In Progress'),
                ),
                DropdownMenuItem(
                  value: 'completed',
                  child: Text('Completed'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _status = value;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }
} 