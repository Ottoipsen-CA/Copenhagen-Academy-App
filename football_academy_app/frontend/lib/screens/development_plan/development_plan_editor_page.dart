import 'package:flutter/material.dart';
import '../../models/development_plan.dart';
import '../../repositories/development_plan_repository.dart';
import '../../services/auth_service.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/navigation_drawer.dart';

class DevelopmentPlanEditorPage extends StatefulWidget {
  final DevelopmentPlan? plan;
  final DevelopmentPlanRepository repository;
  final bool isCreating;

  const DevelopmentPlanEditorPage({
    Key? key,
    this.plan,
    required this.repository,
    required this.isCreating,
  }) : super(key: key);

  @override
  _DevelopmentPlanEditorPageState createState() => _DevelopmentPlanEditorPageState();
}

class _DevelopmentPlanEditorPageState extends State<DevelopmentPlanEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _goalsController;
  late TextEditingController _notesController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.plan?.title ?? '');
    _goalsController = TextEditingController(text: widget.plan?.longTermGoals ?? '');
    _notesController = TextEditingController(text: widget.plan?.notes ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _goalsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _savePlan() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.isCreating) {
        // Get current user ID
        final userId = await AuthService.getCurrentUserId();
        
        // Create new plan
        final newPlan = DevelopmentPlan(
          userId: int.parse(userId), // Convert from String to int
          title: _titleController.text,
          longTermGoals: _goalsController.text,
          notes: _notesController.text,
        );

        await widget.repository.create(newPlan);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Development plan created successfully')),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Update existing plan
        final updatedPlan = widget.plan!.copyWith(
          title: _titleController.text,
          longTermGoals: _goalsController.text,
          notes: _notesController.text,
        );

        await widget.repository.update(updatedPlan);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Development plan updated successfully')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      print('Error saving plan: $e');
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
    
    if (_goalsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter long-term goals')),
      );
      return false;
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomNavigationDrawer(currentPage: 'developmentPlan'),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
        backgroundColor: AppColors.primary,
        title: Text(
          widget.isCreating ? 'Create Development Plan' : 'Edit Development Plan',
          style: const TextStyle(color: Colors.white),
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
              onPressed: _savePlan,
              tooltip: 'Save Plan',
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
                hint: 'Enter a title for this development plan',
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _goalsController,
                label: 'Long-Term Goals',
                hint: 'Describe your long-term development goals',
                maxLines: 5,
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _notesController,
                label: 'Notes',
                hint: 'Any additional notes',
                maxLines: 3,
              ),
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
} 