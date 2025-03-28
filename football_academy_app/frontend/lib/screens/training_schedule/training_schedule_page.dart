import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/training_schedule.dart';
import '../../services/training_schedule_service.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/navigation_drawer.dart';
import 'day_detail_page.dart';

class TrainingSchedulePage extends StatefulWidget {
  static const String routeName = '/training-schedule';
  
  const TrainingSchedulePage({Key? key}) : super(key: key);

  @override
  _TrainingSchedulePageState createState() => _TrainingSchedulePageState();
}

class _TrainingSchedulePageState extends State<TrainingSchedulePage> {
  late Future<WeeklyTrainingSchedule> _scheduleFuture;
  final _weeklyGoalsController = TextEditingController();
  bool _isEditingWeeklyGoals = false;
  
  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }
  
  @override
  void dispose() {
    _weeklyGoalsController.dispose();
    super.dispose();
  }
  
  void _loadSchedule() {
    setState(() {
      _scheduleFuture = TrainingScheduleService.getCurrentSchedule();
    });
  }
  
  Future<void> _saveWeeklyGoals(WeeklyTrainingSchedule schedule) async {
    if (_weeklyGoalsController.text.isEmpty) return;
    
    try {
      final updatedSchedule = await TrainingScheduleService.updateWeeklyGoals(
        schedule, 
        _weeklyGoalsController.text,
      );
      
      setState(() {
        _isEditingWeeklyGoals = false;
        _scheduleFuture = Future.value(updatedSchedule);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save goals: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Weekly Schedule',
      ),
      drawer: const CustomNavigationDrawer(currentPage: 'training'),
      body: GradientBackground(
        child: FutureBuilder<WeeklyTrainingSchedule>(
          future: _scheduleFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading schedule: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }
            
            if (!snapshot.hasData) {
              return const Center(
                child: Text(
                  'No schedule found',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            
            final schedule = snapshot.data!;
            return _buildScheduleContent(schedule);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Refresh the schedule
          _loadSchedule();
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.refresh),
      ),
    );
  }
  
  Widget _buildScheduleContent(WeeklyTrainingSchedule schedule) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week date range
          _buildWeekHeader(schedule),
          
          // Weekly goals
          _buildWeeklyGoals(schedule),
          
          // Daily schedule
          Expanded(
            child: ListView.builder(
              itemCount: schedule.days.length,
              itemBuilder: (context, index) {
                final day = schedule.days[index];
                return _buildDayCard(day, schedule);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWeekHeader(WeeklyTrainingSchedule schedule) {
    final endDate = schedule.weekStartDate.add(const Duration(days: 6));
    final dateFormat = DateFormat('MMM d');
    
    return Card(
      color: AppColors.cardBackground.withOpacity(0.5),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Week of ${dateFormat.format(schedule.weekStartDate)} - ${dateFormat.format(endDate)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWeeklyGoals(WeeklyTrainingSchedule schedule) {
    if (_isEditingWeeklyGoals) {
      return Card(
        color: AppColors.cardBackground.withOpacity(0.8),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weekly Goals',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _weeklyGoalsController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter your goals for this week...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isEditingWeeklyGoals = false;
                      });
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _saveWeeklyGoals(schedule),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _weeklyGoalsController.text = schedule.weeklyGoals ?? '';
          _isEditingWeeklyGoals = true;
        });
      },
      child: Card(
        color: AppColors.cardBackground.withOpacity(0.8),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.flag,
                        color: Colors.orange,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Weekly Goals',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                    onPressed: () {
                      setState(() {
                        _weeklyGoalsController.text = schedule.weeklyGoals ?? '';
                        _isEditingWeeklyGoals = true;
                      });
                    },
                  ),
                ],
              ),
              if (schedule.weeklyGoals != null && schedule.weeklyGoals!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    schedule.weeklyGoals!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Tap to add weekly goals...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDayCard(TrainingDay day, WeeklyTrainingSchedule schedule) {
    final hasContent = day.sessions.isNotEmpty || day.matches.isNotEmpty || day.goals != null;
    
    // Determine weekday number (0-6) to find highlight current day
    final weekdayIndex = TrainingDay.weekdays.indexOf(day.day);
    final now = DateTime.now();
    final isToday = now.weekday - 1 == weekdayIndex; // weekday is 1-7, index is 0-6
    
    return Card(
      color: AppColors.cardBackground,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isToday
            ? const BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () async {
          // Navigate to day detail page
          final updatedDay = await Navigator.push<TrainingDay>(
            context,
            MaterialPageRoute(
              builder: (context) => DayDetailPage(
                day: day,
                schedule: schedule,
              ),
            ),
          );
          
          if (updatedDay != null) {
            // Refresh schedule with updated day
            final updatedSchedule = schedule.updateDay(updatedDay);
            setState(() {
              _scheduleFuture = Future.value(updatedSchedule);
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isToday 
                              ? Colors.green.withOpacity(0.2) 
                              : AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          day.day,
                          style: TextStyle(
                            color: isToday ? Colors.green : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'TODAY',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Activity count
                  Row(
                    children: [
                      if (day.sessions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Chip(
                            backgroundColor: Colors.blue.withOpacity(0.2),
                            visualDensity: VisualDensity.compact,
                            label: Text(
                              '${day.sessions.length} ${day.sessions.length == 1 ? "Training" : "Trainings"}',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      if (day.matches.isNotEmpty)
                        Chip(
                          backgroundColor: Colors.red.withOpacity(0.2),
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            '${day.matches.length} ${day.matches.length == 1 ? "Match" : "Matches"}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              // Training sessions
              if (day.sessions.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...day.sessions.take(2).map((session) => _buildSessionItem(session)),
                if (day.sessions.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '+ ${day.sessions.length - 2} more sessions',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
              
              // Matches
              if (day.matches.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...day.matches.take(1).map((match) => _buildMatchItem(match)),
                if (day.matches.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '+ ${day.matches.length - 1} more matches',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
              
              // Day goals
              if (day.goals != null && day.goals!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.flag,
                            color: Colors.orange,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Goals:',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        day.goals!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
              
              // Empty state
              if (!hasContent) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'No activities scheduled',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              
              // View details button
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    // Navigate to day detail page
                    final updatedDay = await Navigator.push<TrainingDay>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DayDetailPage(
                          day: day,
                          schedule: schedule,
                        ),
                      ),
                    );
                    
                    if (updatedDay != null) {
                      // Refresh schedule with updated day
                      final updatedSchedule = schedule.updateDay(updatedDay);
                      setState(() {
                        _scheduleFuture = Future.value(updatedSchedule);
                      });
                    }
                  },
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Details'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSessionItem(TrainingSession session) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              session.timeRange,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (session.location != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white54,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          session.location!,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (session.type != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        session.type!,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Intensity indicator
          _buildIntensityIndicator(session.intensity),
        ],
      ),
    );
  }
  
  Widget _buildIntensityIndicator(int intensity) {
    Color color;
    switch (intensity) {
      case 1:
        color = Colors.green;
        break;
      case 2:
        color = Colors.lightGreen;
        break;
      case 3:
        color = Colors.yellow;
        break;
      case 4:
        color = Colors.orange;
        break;
      case 5:
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    
    return Column(
      children: [
        Text(
          'Intensity',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$intensity',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMatchItem(Match match) {
    final matchTime = DateFormat('HH:mm').format(match.dateTime);
    final matchDay = DateFormat('E, MMM d').format(match.dateTime);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.sports_soccer,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.matchTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Colors.white54,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$matchDay - $matchTime',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (match.location != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white54,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            match.location!,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (match.competition != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  match.competition!,
                  style: const TextStyle(
                    color: Colors.purple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 