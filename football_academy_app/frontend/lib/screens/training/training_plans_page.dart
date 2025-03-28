import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/training_plan.dart';
import '../../services/auth_service.dart';
import '../../services/exercise_service.dart';
import '../../services/training_plan_service.dart';
import '../../widgets/navigation_drawer.dart';
import 'training_plan_detail_page.dart';
import 'create_training_plan_page.dart';

class TrainingPlansPage extends StatefulWidget {
  const TrainingPlansPage({super.key});

  @override
  State<TrainingPlansPage> createState() => _TrainingPlansPageState();
}

class _TrainingPlansPageState extends State<TrainingPlansPage> with SingleTickerProviderStateMixin {
  late TrainingPlanService _trainingPlanService;
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  List<TrainingPlan> _activePlans = [];
  List<TrainingPlan> _completedPlans = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize services
    final authService = Provider.of<AuthService>(context, listen: false);
    _trainingPlanService = TrainingPlanService(authService, null);
    
    _loadTrainingPlans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrainingPlans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final plans = await _trainingPlanService.getUserTrainingPlans();
      
      setState(() {
        _activePlans = plans.where((plan) => plan.progress < 100).toList();
        _completedPlans = plans.where((plan) => plan.progress >= 100).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center, size: 24),
            const SizedBox(width: 10),
            const Text('Training Plans'),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0B0057),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Active Plans'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      drawer: const CustomNavigationDrawer(currentPage: 'training'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B0057), // Dark blue/purple
              Color(0xFF1C006C), // Mid purple
              Color(0xFF3D007A), // Lighter purple
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _errorMessage != null
                ? Center(
                    child: Text(
                      'Error: $_errorMessage',
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                : _buildTabBarView(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateTrainingPlanPage(),
            ),
          ).then((_) => _loadTrainingPlans());
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        // Active Plans Tab
        _buildPlansListView(_activePlans, 'active'),
        
        // Completed Plans Tab
        _buildPlansListView(_completedPlans, 'completed'),
      ],
    );
  }

  Widget _buildPlansListView(List<TrainingPlan> plans, String type) {
    if (plans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                type == 'active' ? Icons.fitness_center : Icons.emoji_events,
                size: 64,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                type == 'active'
                    ? 'No active training plans'
                    : 'No completed training plans yet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                type == 'active'
                    ? 'Create a new training plan to start improving your skills'
                    : 'Complete a training plan to see it here',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              if (type == 'active')
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateTrainingPlanPage(),
                        ),
                      ).then((_) => _loadTrainingPlans());
                    },
                    icon: Icon(Icons.add),
                    label: Text('Create Training Plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrainingPlans,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: plans.length,
        itemBuilder: (context, index) {
          final plan = plans[index];
          return _buildTrainingPlanCard(plan);
        },
      ),
    );
  }

  Widget _buildTrainingPlanCard(TrainingPlan plan) {
    // Calculate progress for active plans
    final totalSessions = plan.weeks.fold(
      0,
      (total, week) => total + week.sessions.length,
    );
    
    final completedSessions = plan.weeks.fold(
      0,
      (total, week) => total +
          week.sessions.where((session) => session.isCompleted).length,
    );
    
    // Use the progress from the model instead of calculating
    final progress = plan.progress / 100;
    
    // Calculate days left for active plans
    final startDate = plan.startDate;
    final endDate = plan.endDate;
    final daysLeft = endDate.difference(DateTime.now()).inDays;
    
    // Extract the first focus area for coloring
    final focusAreaText = plan.focusArea.isNotEmpty ? plan.focusArea[0] : "General";
    
    // Determine card color based on focus area
    Color cardColor;
    switch (focusAreaText.toLowerCase()) {
      case 'shooting':
        cardColor = Colors.orange.shade800;
        break;
      case 'passing':
        cardColor = Colors.green.shade700;
        break;
      case 'dribbling':
        cardColor = Colors.blue.shade700;
        break;
      case 'defending':
        cardColor = Colors.red.shade700;
        break;
      case 'physical':
        cardColor = Colors.purple.shade700;
        break;
      default:
        cardColor = Colors.blueGrey.shade700;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: cardColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TrainingPlanDetailPage(planId: plan.id),
            ),
          ).then((_) => _loadTrainingPlans());
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with color
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getFocusAreaIcon(focusAreaText),
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      plan.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      plan.focusArea.join('/'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Body
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress info for active plans
                  if (plan.progress < 100) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Progress',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$completedSessions / $totalSessions sessions completed',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Column(
                            children: [
                              Text(
                                daysLeft.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'days left',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Completed plan info
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Completed',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${endDate.difference(startDate).inDays ~/ 7} weeks',
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  
                  // Duration and level
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white54,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${endDate.difference(startDate).inDays ~/ 7} weeks program',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.signal_cellular_alt,
                        color: Colors.white54,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        plan.playerLevel,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // View details button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TrainingPlanDetailPage(planId: plan.id),
                          ),
                        ).then((_) => _loadTrainingPlans());
                      },
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('View Details'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getFocusAreaIcon(String focusArea) {
    switch (focusArea.toLowerCase()) {
      case 'shooting':
        return Icons.sports_soccer;
      case 'passing':
        return Icons.swap_horiz;
      case 'dribbling':
        return Icons.move_down;
      case 'defending':
        return Icons.shield;
      case 'physical':
        return Icons.fitness_center;
      default:
        return Icons.sports;
    }
  }
} 