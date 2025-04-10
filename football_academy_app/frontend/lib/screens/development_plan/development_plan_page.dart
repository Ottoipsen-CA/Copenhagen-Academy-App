import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/development_plan.dart';
import '../../services/development_plan_service.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/gradient_background.dart';
import 'development_plan_editor_page.dart';
import 'session_details_page.dart';
import 'development_focus_editor_page.dart';

class DevelopmentPlanPage extends StatefulWidget {
  final DevelopmentPlanService service;

  const DevelopmentPlanPage({
    Key? key,
    required this.service,
  }) : super(key: key);

  @override
  _DevelopmentPlanPageState createState() => _DevelopmentPlanPageState();
}

class _DevelopmentPlanPageState extends State<DevelopmentPlanPage> with SingleTickerProviderStateMixin {
  late Future<List<DevelopmentPlan>> _plansFuture;
  bool _isLoading = false;
  late TabController _tabController;
  DevelopmentPlan? _plan;
  int _currentPageIndex = 0; // 0=Monday, 6=Sunday
  late PageController _pageController; // Controller for PageView

  final List<String> _weekdays = [
    'Mandag', // Full names for indicator
    'Tirsdag',
    'Onsdag',
    'Torsdag',
    'Fredag',
    'Lørdag',
    'Søndag',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pageController = PageController(initialPage: _currentPageIndex); // Initialize PageController
    _loadPlans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose(); // Dispose PageController
    super.dispose();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      print('Token retrieved: ${token != null}');
      
      final plans = await widget.service.getDevelopmentPlans();
      if (mounted) {
        setState(() {
          _plan = plans.isNotEmpty ? plans.first : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing service: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _plan = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading development plans: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Development Plan',
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Weekly Schedule'),
            Tab(text: 'Development Focus'),
          ],
        ),
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _plan == null
                ? const Center(child: Text('No development plan found', style: TextStyle(color: Colors.white)))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildWeeklySchedulePageView(),
                      _buildDevelopmentFocus(),
                    ],
                  ),
      ),
      floatingActionButton: _tabController.index == 0 && _plan != null // Only show on schedule tab
       ? FloatingActionButton(
          onPressed: () => _addSession(_currentPageIndex + 1), // Pass current weekday
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
          tooltip: 'Tilføj Træning',
        )
      : null,
    );
  }

  Widget _buildWeeklySchedulePageView() {
    return Column(
      children: [
        _buildDayIndicator(),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: 7,
            itemBuilder: (context, index) {
              return _buildDayPage(index);
            },
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      color: AppColors.cardBackground.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final isSelected = _currentPageIndex == index;
          return TextButton(
            style: TextButton.styleFrom(
              backgroundColor: isSelected ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Text(
              _weekdays[index].substring(0, 3),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayPage(int index) {
    if (_plan == null) return const Center(child: CircularProgressIndicator(color: Colors.white));

    final weekday = index + 1;
    final sessions = _plan!.trainingSessions
        .where((session) => session.weekday == weekday)
        .toList();

    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'Ingen træninger planlagt for ${_weekdays[index]}', 
            style: const TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      key: PageStorageKey('weekday_$weekday'),
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, sessionIndex) {
        return _buildSessionCard(sessions[sessionIndex]);
      },
    );
  }

  Widget _buildSessionCard(TrainingSession session) {
    final timeStr = session.startTime ?? '-';
    final durationStr = session.durationMinutes != null ? '${session.durationMinutes} min' : '-';
    final isMatch = session.title.toLowerCase().contains('match');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.cardBackground.withOpacity(0.8), 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(
          isMatch ? Icons.sports_soccer : Icons.fitness_center,
          color: AppColors.primary, 
        ),
        title: Text(session.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text('$timeStr ($durationStr)', style: const TextStyle(color: Colors.white70)),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          onPressed: () => _viewSessionDetails(session),
        ),
        onTap: () => _viewSessionDetails(session),
      ),
    );
  }

  Widget _buildDevelopmentFocus() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSection(
          title: 'Long-Term Goals',
          content: _plan!.longTermGoals ?? 'No long-term goals defined',
        ),
        const SizedBox(height: 24),
        _buildSection(
          title: 'Focus Areas',
          child: Column(
            children: [
              if (_plan!.focusAreas.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No focus areas defined',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              else
                ..._plan!.focusAreas.map((area) => _buildFocusAreaCard(area)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _editDevelopmentFocus(),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Development Focus'),
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
          content: _plan!.notes ?? 'No notes available',
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    String? content,
    Widget? child,
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
        if (content != null)
          Text(
            content,
            style: const TextStyle(color: Colors.white),
          )
        else if (child != null)
          child,
      ],
    );
  }

  Widget _buildFocusAreaCard(FocusArea area) {
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
                if (area.isCompleted)
                  const Chip(
                    label: Text('Completed'),
                    backgroundColor: Colors.green,
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

  void _addSession(int weekday) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tilføj træning for ${_weekdays[weekday-1]} (kommer snart)')),
    );
  }

  void _viewSessionDetails(TrainingSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionDetailsPage(
          session: session,
          onSave: (updatedSession) {
            // TODO: Implement session update functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Session update functionality coming soon')),
            );
          },
        ),
      ),
    );
  }

  void _editDevelopmentFocus() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DevelopmentFocusEditorPage(
          plan: _plan!,
          onSave: _updatePlan,
        ),
      ),
    );
  }

  Future<void> _updatePlan(DevelopmentPlan updatedPlan) async {
    try {
      await widget.service.updateDevelopmentPlan(updatedPlan);
      setState(() {
        _plan = updatedPlan;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Development plan updated successfully')),
      );
    } catch (e) {
      print('Error updating plan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update development plan')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
