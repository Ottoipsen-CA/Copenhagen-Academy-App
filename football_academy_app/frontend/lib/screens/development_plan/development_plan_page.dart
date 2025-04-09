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
    _loadPlans();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        backgroundColor: const Color(0xFF0B0057),
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
                      _buildWeeklyScheduleListView(),
                      _buildDevelopmentFocus(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildWeeklyScheduleListView() {
    if (_plan == null) return const Center(child: CircularProgressIndicator(color: Colors.white));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _weekdays.length,
      itemBuilder: (context, index) {
        final dayName = _weekdays[index];
        final weekday = index + 1;

        final sessions = _plan!.trainingSessions
            .where((session) => session.weekday == weekday)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: Text(
                dayName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (sessions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    'Ingen træninger planlagt for $dayName',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Column(
                children: sessions.map((session) => _buildSessionCard(session)).toList(),
              ),
            if (index < _weekdays.length - 1)
             Divider(color: Colors.white24, height: 32), 
          ],
        );
      },
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
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B0057).withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
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

  Widget _buildSessionCard(TrainingSession session) {
    final timeStr = session.startTime ?? '-';
    final durationStr = session.durationMinutes != null ? '${session.durationMinutes} min' : '-';
    final isMatch = session.title.toLowerCase().contains('match');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF0B0057).withOpacity(0.6),
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
}
