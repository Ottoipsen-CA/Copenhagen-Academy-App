import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/development_plan.dart';
import '../../repositories/development_plan_repository.dart';
import '../../theme/colors.dart';
import '../../widgets/gradient_background.dart';

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

        print('Creating new focus area: ${newFocusArea.toJson()}');
        final createdFocusArea = await widget.repository.createFocusArea(newFocusArea);
        print('Focus area created successfully: ${createdFocusArea.focusAreaId}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fokusområde oprettet')),
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
          status: _status,
        );

        print('Updating focus area: ${updatedFocusArea.toJson()}');
        final updatedResult = await widget.repository.updateFocusArea(updatedFocusArea);
        print('Focus area updated successfully: ${updatedResult.focusAreaId}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fokusområde opdateret')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      print('Error saving focus area: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fejl: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Prøv igen',
              onPressed: _saveFocusArea,
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
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indtast venligst en beskrivelse')),
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
          widget.isCreating ? 'Tilføj Fokusområde' : 'Rediger Fokusområde',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Tilbage',
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
              tooltip: 'Gem Fokusområde',
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
                hint: 'Indtast en titel til dette fokusområde',
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _descriptionController,
                label: 'Beskrivelse',
                hint: 'Beskriv hvad du vil opnå i dette område',
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

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prioritet',
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
          child: Column(
            children: [
              _buildPriorityItem(1, 'Høj'),
              _buildPriorityItem(2, 'Medium'),
              _buildPriorityItem(3, 'Lav'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityItem(int value, String label) {
    return RadioListTile<int>(
      title: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
      value: value,
      groupValue: _priority,
      activeColor: Colors.white,
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() {
            _priority = newValue;
          });
        }
      },
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Måldato',
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
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(_targetDate),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const Icon(Icons.calendar_today, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSelector() {
    final Map<String, String> statusLabels = {
      'not_started': 'Ikke påbegyndt',
      'in_progress': 'I gang',
      'completed': 'Gennemført',
    };
    
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: statusLabels.entries.map((entry) {
              return RadioListTile<String>(
                title: Text(
                  entry.value, 
                  style: const TextStyle(color: Colors.white),
                ),
                value: entry.key,
                groupValue: _status,
                activeColor: Colors.white,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
} 