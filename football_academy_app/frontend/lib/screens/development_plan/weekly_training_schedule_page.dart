import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/training_schedule.dart';
import '../../repositories/training_schedule_repository.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/colors.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/navigation_drawer.dart';

class WeeklyTrainingSchedulePage extends StatefulWidget {
  const WeeklyTrainingSchedulePage({Key? key}) : super(key: key);

  @override
  _WeeklyTrainingSchedulePageState createState() => _WeeklyTrainingSchedulePageState();
}

class _WeeklyTrainingSchedulePageState extends State<WeeklyTrainingSchedulePage> {
  late TrainingScheduleRepository _repository;
  late int _userId;
  int _currentWeek = 0;  // Initialize with default value
  int _currentYear = 0;  // Initialize with default value
  bool _isLoading = true;
  TrainingSchedule? _currentSchedule;
  List<TrainingSession> _sessions = [];
  List<DateTime> _weekDates = [];
  
  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    _repository = TrainingScheduleRepository(apiService);
    
    // Get current user ID
    try {
      final userInfo = await authService.getUserInfo();
      _userId = userInfo['id'];
    } catch (e) {
      print('Error getting user info: $e');
      _userId = 1; // Default to user 1 if we can't get the actual user
    }
    
    // Get current week number
    final now = DateTime.now();
    _currentYear = now.year;
    _currentWeek = _repository.getCurrentWeekNumber();
    
    await _loadWeekData();
  }
  
  Future<void> _loadWeekData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get week dates
      _weekDates = _repository.getDatesForWeek(_currentYear, _currentWeek);
      
      // Try to load existing schedule for this week
      final schedule = await _repository.getScheduleByWeek(_userId, _currentWeek, _currentYear);
      
      if (schedule != null) {
        _currentSchedule = schedule;
        // Load all sessions for this schedule
        _sessions = await _repository.getSessionsForSchedule(schedule.id!);
      } else {
        _currentSchedule = null;
        _sessions = [];
      }
    } catch (e) {
      print('Error loading training schedule: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fejl ved indlæsning af træningsplan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _changeWeek(int direction) {
    // direction: 1 for next week, -1 for previous week
    if (direction > 0) {
      if (_currentWeek == 52) {
        _currentWeek = 1;
        _currentYear += 1;
      } else {
        _currentWeek += 1;
      }
    } else {
      if (_currentWeek == 1) {
        _currentWeek = 52;
        _currentYear -= 1;
      } else {
        _currentWeek -= 1;
      }
    }
    
    _loadWeekData();
  }
  
  Future<bool> _createScheduleIfNeeded() async {
    if (_currentSchedule != null) return true;
    
    try {
      // Create a new schedule for this week
      final newSchedule = TrainingSchedule(
        userId: _userId,
        weekNumber: _currentWeek,
        year: _currentYear,
        title: 'Træningsuge $_currentWeek, $_currentYear',
      );
      
      _currentSchedule = await _repository.createSchedule(newSchedule);
      return true;
    } catch (e) {
      print('Error creating training schedule: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fejl ved oprettelse af træningsplan: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }
  
  Future<void> _addTrainingSession(int dayIndex) async {
    // Make sure we have a schedule first
    bool hasSchedule = await _createScheduleIfNeeded();
    if (!hasSchedule) return;
    
    final sessionDate = _weekDates[dayIndex];
    
    // Default time values for the dialog
    final TimeOfDay defaultStartTime = TimeOfDay(hour: 16, minute: 0);
    final TimeOfDay defaultEndTime = TimeOfDay(hour: 17, minute: 30);
    
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    
    String startTime = '${defaultStartTime.hour.toString().padLeft(2, '0')}:${defaultStartTime.minute.toString().padLeft(2, '0')}:00';
    String endTime = '${defaultEndTime.hour.toString().padLeft(2, '0')}:${defaultEndTime.minute.toString().padLeft(2, '0')}:00';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('Tilføj Træning - ${_getDayName(dayIndex)}',
          style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  DateFormat('d. MMMM yyyy').format(sessionDate),
                  style: const TextStyle(color: Colors.white70)
                ),
              ),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Titel',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        'Start: ${defaultStartTime.format(context)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: defaultStartTime,
                        );
                        if (picked != null) {
                          startTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        'Slut: ${defaultEndTime.format(context)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: defaultEndTime,
                        );
                        if (picked != null) {
                          endTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Sted',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Beskrivelse',
                  alignLabelWithHint: true,
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULLER', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () async {
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Titel er påkrævet')),
                );
                return;
              }
              
              try {
                final newSession = TrainingSession(
                  scheduleId: _currentSchedule!.id!,
                  dayOfWeek: dayIndex + 1, // 1-7 for Monday-Sunday
                  sessionDate: sessionDate,
                  title: titleController.text,
                  description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
                  startTime: startTime,
                  endTime: endTime,
                  location: locationController.text.isNotEmpty ? locationController.text : null,
                );
                
                await _repository.createSession(newSession);
                
                if (mounted) {
                  Navigator.pop(context, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Træning tilføjet')),
                  );
                }
              } catch (e) {
                print('Error creating training session: $e');
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fejl ved oprettelse af træning: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('GEM'),
          ),
        ],
      ),
    ).then((result) {
      if (result == true) {
        // Refresh data
        _loadWeekData();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Week selector - matches the plan selector style
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          color: AppColors.primary.withOpacity(0.8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.white),
                onPressed: () => _changeWeek(-1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 24),
              Text(
                'UGE $_currentWeek',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.white),
                onPressed: () => _changeWeek(1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        
        // Vertical list of days or loading indicator
        _isLoading
        ? const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          )
        : Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              itemCount: 7, // 7 days in a week
              itemBuilder: (context, index) => _buildDayCard(index),
            ),
          ),
      ],
    );
  }

  Widget _buildDayCard(int dayIndex) {
    final sessionDate = _weekDates[dayIndex];
    final List<TrainingSession> daySessions = _getSessionsForDay(dayIndex);
    final bool hasSession = daySessions.isNotEmpty;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.cardBackground.withOpacity(hasSession ? 0.9 : 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        collapsedBackgroundColor: hasSession 
            ? AppColors.primary.withOpacity(0.8) 
            : AppColors.cardBackground.withOpacity(0.8),
        backgroundColor: AppColors.cardBackground,
        leading: CircleAvatar(
          backgroundColor: hasSession ? AppColors.primary : Colors.grey.shade700,
          child: Text(
            sessionDate.day.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          _getDayName(dayIndex),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: hasSession
            ? _buildSessionIndicators(daySessions)
            : IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
                onPressed: () => _addTrainingSession(dayIndex),
                tooltip: 'Tilføj træning',
              ),
        children: [
          if (hasSession)
            ...daySessions.map((session) => _buildSessionItem(session)),
          if (!hasSession)
            ListTile(
              title: const Text(
                'Ingen træninger planlagt',
                style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
              ),
              trailing: TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('TILFØJ'),
                onPressed: () => _addTrainingSession(dayIndex),
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionIndicators(List<TrainingSession> sessions) {
    final hasReflection = sessions.any((s) => s.hasReflection);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasReflection)
          const Icon(Icons.rate_review, size: 16, color: Colors.green),
        const SizedBox(width: 8),
        Text(
          '${sessions.length} ${sessions.length == 1 ? 'træning' : 'træninger'}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const Icon(Icons.expand_more, color: Colors.white70),
      ],
    );
  }

  Widget _buildSessionItem(TrainingSession session) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () => _showSessionDetails(session),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.directions_run, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.formattedTime,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (session.hasReflection)
                const Tooltip(
                  message: 'Refleksioner tilføjet',
                  child: Icon(Icons.rate_review, size: 16, color: Colors.green),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.navigate_next, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSessionDetailsSheet(TrainingSession session) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (_, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${session.getDayName()}, ${session.formattedDate} · ${session.formattedTime}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white70),
                    onPressed: () async {
                      // Close the details sheet first
                      Navigator.pop(context);
                      
                      // TODO: Implement edit functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Redigering er under udvikling')),
                      );
                    },
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 32),
              
              // Description section
              if (session.location != null) ...[
                const Text(
                  'LOKATION',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  session.location!,
                  style: const TextStyle(color: Colors.white, height: 1.4),
                ),
                const SizedBox(height: 16),
              ],
              
              const Text(
                'BESKRIVELSE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                session.description ?? 'Ingen beskrivelse tilføjet',
                style: TextStyle(
                  color: session.description != null ? Colors.white : Colors.white54,
                  height: 1.4,
                  fontStyle: session.description != null ? FontStyle.normal : FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
              
              // Reflections section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'REFLEKSIONER',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!session.hasReflection)
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('TILFØJ'),
                      onPressed: () {
                        Navigator.pop(context);
                        _addReflection(session);
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              
              session.hasReflection
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.reflectionText ?? '',
                          style: const TextStyle(color: Colors.white, height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              session.reflectionAddedAt != null 
                                ? 'Tilføjet: ${DateFormat('d. MMMM').format(session.reflectionAddedAt!)}'
                                : '',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              child: const Icon(Icons.edit, size: 16, color: Colors.white54),
                              onTap: () {
                                Navigator.pop(context);
                                _addReflection(session, isEdit: true);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const Text(
                    'Ingen refleksioner tilføjet endnu',
                    style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                  ),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('SLET'),
                      onPressed: () {
                        Navigator.pop(context);
                        _showDeleteConfirmation(session);
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('LUK'),
                      style: TextButton.styleFrom(foregroundColor: Colors.white70),
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
  
  Future<void> _showDeleteConfirmation(TrainingSession session) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Slet træningssession', style: TextStyle(color: Colors.white)),
        content: Text('Er du sikker på, at du vil slette "${session.title}"?', 
                    style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuller', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Slet', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await _repository.deleteSession(session.id!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Træningssession slettet')),
          );
          // Reload data
          _loadWeekData();
        }
      } catch (e) {
        print('Error deleting session: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fejl ved sletning: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  // Helper methods
  
  // Get sessions for a specific day
  List<TrainingSession> _getSessionsForDay(int dayIndex) {
    final dayOfWeek = dayIndex + 1; // 1-7 for Monday-Sunday
    return _sessions.where((session) => session.dayOfWeek == dayOfWeek).toList();
  }
  
  // Get day name from index
  String _getDayName(int dayIndex) {
    final List<String> dayNames = ['Mandag', 'Tirsdag', 'Onsdag', 'Torsdag', 'Fredag', 'Lørdag', 'Søndag'];
    return dayNames[dayIndex];
  }
  
  // Show session details
  Future<void> _showSessionDetails(TrainingSession session) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildSessionDetailsSheet(session),
    ).then((result) {
      if (result == true) {
        // Refresh data
        _loadWeekData();
      }
    });
  }

  // Add or edit reflection
  Future<void> _addReflection(TrainingSession session, {bool isEdit = false}) async {
    TextEditingController textController = TextEditingController();
    if (isEdit && session.reflectionText != null) {
      textController.text = session.reflectionText!;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(isEdit ? 'Rediger Refleksion' : 'Tilføj Refleksion',
          style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: textController,
          style: const TextStyle(color: Colors.white),
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Skriv dine tanker om træningen...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white30),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULLER', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () async {
              if (textController.text.isNotEmpty) {
                try {
                  await _repository.addReflection(session.id!, textController.text);
                  
                  if (mounted) {
                    Navigator.pop(context, true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEdit ? 'Refleksion opdateret' : 'Refleksion tilføjet')),
                    );
                  }
                } catch (e) {
                  print('Error adding reflection: $e');
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Fejl: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('GEM'),
          ),
        ],
      ),
    ).then((result) {
      if (result == true) {
        // Refresh data
        _loadWeekData();
      }
    });
  }
} 