import 'package:flutter/material.dart';
import '../../models/development_plan.dart';
import '../../repositories/development_plan_repository.dart';
import '../../services/auth_service.dart';
import '../../theme/colors.dart';
import '../../widgets/gradient_background.dart';

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

        print('Creating new development plan: ${newPlan.toJson()}');
        final createdPlan = await widget.repository.create(newPlan);
        print('Development plan created successfully: ${createdPlan.planId}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Udviklingsplan oprettet')),
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

        print('Updating development plan: ${updatedPlan.toJson()}');
        final updatedResult = await widget.repository.update(updatedPlan);
        print('Development plan updated successfully: ${updatedResult.planId}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Udviklingsplan opdateret')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      print('Error saving plan: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fejl: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Prøv igen',
              onPressed: _savePlan,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  bool _validateInputs() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indtast venligst en titel')),
      );
      return false;
    }
    
    if (_goalsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indtast venligst langsigtede mål')),
      );
      return false;
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Tilbage til Udviklingsplaner',
        ),
        backgroundColor: AppColors.primary,
        title: Text(
          widget.isCreating ? 'Opret Udviklingsplan' : 'Rediger Udviklingsplan',
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
              tooltip: 'Gem Plan',
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
                label: 'Titel',
                hint: 'Indtast en titel til denne udviklingsplan',
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _goalsController,
                label: 'Langsigtede mål',
                hint: 'Beskriv dine langsigtede udviklingsmål',
                maxLines: 5,
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _notesController,
                label: 'Noter',
                hint: 'Eventuelle yderligere noter',
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
            textCapitalization: TextCapitalization.sentences,
            keyboardType: maxLines > 1 ? TextInputType.multiline : TextInputType.text,
            textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.done,
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