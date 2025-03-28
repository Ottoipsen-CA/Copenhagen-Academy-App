import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/training_schedule.dart';
import '../../theme/colors.dart';

class AddTrainingSessionDialog extends StatefulWidget {
  const AddTrainingSessionDialog({Key? key}) : super(key: key);

  @override
  _AddTrainingSessionDialogState createState() => _AddTrainingSessionDialogState();
}

class _AddTrainingSessionDialogState extends State<AddTrainingSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _typeController = TextEditingController();
  
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(
    hour: TimeOfDay.now().hour + 1,
  );
  
  int _intensity = 3; // Default intensity
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _typeController.dispose();
    super.dispose();
  }
  
  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.cardBackground,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppColors.secondaryBackground,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
        // If end time is before start time, adjust it
        if (_timeToMinutes(_endTime) <= _timeToMinutes(_startTime)) {
          _endTime = TimeOfDay(
            hour: (_startTime.hour + 1) % 24,
            minute: _startTime.minute,
          );
        }
      });
    }
  }
  
  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.cardBackground,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppColors.secondaryBackground,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
      });
    }
  }
  
  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }
  
  bool _isEndTimeValid() {
    return _timeToMinutes(_endTime) > _timeToMinutes(_startTime);
  }
  
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  void _submit() {
    if (_formKey.currentState!.validate() && _isEndTimeValid()) {
      final session = TrainingSession(
        title: _titleController.text,
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        intensity: _intensity,
        description: _descriptionController.text.isNotEmpty 
            ? _descriptionController.text 
            : null,
        location: _locationController.text.isNotEmpty 
            ? _locationController.text 
            : null,
        type: _typeController.text.isNotEmpty 
            ? _typeController.text 
            : null,
      );
      
      Navigator.of(context).pop(session);
    } else if (!_isEndTimeValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.secondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Training Session',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title field
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Title*',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.title,
                      color: Colors.white70,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Time range
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectStartTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Start Time',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _startTime.format(context),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectEndTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: !_isEndTimeValid()
                                ? Border.all(color: Colors.red, width: 1.5)
                                : null,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'End Time',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _endTime.format(context),
                                      style: TextStyle(
                                        color: !_isEndTimeValid()
                                            ? Colors.red
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!_isEndTimeValid())
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0, left: 12.0),
                    child: Text(
                      'End time must be after start time',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                
                // Intensity slider
                Text(
                  'Intensity: $_intensity',
                  style: TextStyle(
                    color: _getIntensityColor(_intensity),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Slider(
                  value: _intensity.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: _getIntensityColor(_intensity),
                  inactiveColor: _getIntensityColor(_intensity).withOpacity(0.3),
                  label: _intensity.toString(),
                  onChanged: (value) {
                    setState(() {
                      _intensity = value.round();
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Location field
                TextFormField(
                  controller: _locationController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Location (optional)',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.location_on,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Type field
                TextFormField(
                  controller: _typeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Type (optional)',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.category,
                      color: Colors.white70,
                    ),
                    hintText: 'Technical, Tactical, Physical, etc.',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Description field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.description,
                          color: Colors.blue,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Description',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Describe what you'll do in this session...",
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Color _getIntensityColor(int intensity) {
    switch (intensity) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
} 