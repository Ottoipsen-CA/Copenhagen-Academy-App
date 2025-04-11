import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/development_plan.dart';
import '../../repositories/development_plan_repository.dart';
import '../../services/api_service.dart';
import '../../theme/colors.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/navigation_drawer.dart';
import 'development_plan_editor_page.dart';
import 'session_details_page.dart';
import 'development_focus_editor_page.dart';

class DevelopmentPlanPage extends StatefulWidget {
  const DevelopmentPlanPage({
    Key? key,
  }) : super(key: key);

  @override
  _DevelopmentPlanPageState createState() => _DevelopmentPlanPageState();
}

class _DevelopmentPlanPageState extends State<DevelopmentPlanPage> with SingleTickerProviderStateMixin {
  late Future<List<DevelopmentPlan>> _plansFuture;
  bool _isLoading = false;
  late TabController _tabController;
  DevelopmentPlan? _selectedPlan;
  List<DevelopmentPlan> _plans = [];
  List<FocusArea> _focusAreas = [];
  late DevelopmentPlanRepository _repository;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _repository = DevelopmentPlanRepository(Provider.of<ApiService>(context, listen: false));
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
      final plans = await _repository.getUserPlans();
      
      // Sort plans by created_at date, most recent first
      plans.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      
      if (mounted) {
        setState(() {
          _plans = plans;
          _selectedPlan = plans.isNotEmpty ? plans.first : null;
          _isLoading = false;
        });
        
        if (_selectedPlan != null) {
          _loadFocusAreas(_selectedPlan!.planId!);
        }
      }
    } catch (e) {
      print('Error loading development plans: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedPlan = null;
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
  
  Future<void> _loadFocusAreas(int planId) async {
    try {
      final focusAreas = await _repository.getFocusAreas(planId);
      if (mounted) {
        setState(() {
          _focusAreas = focusAreas;
        });
      }
    } catch (e) {
      print('Error loading focus areas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading focus areas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onPlanSelected(DevelopmentPlan plan) {
    setState(() {
      _selectedPlan = plan;
    });
    _loadFocusAreas(plan.planId!);
  }

  Future<void> _createNewPlan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DevelopmentPlanEditorPage(
          isCreating: true,
          repository: _repository,
        ),
      ),
    );

    if (result == true) {
      _loadPlans();
    }
  }

  Future<void> _editPlan() async {
    if (_selectedPlan == null) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DevelopmentPlanEditorPage(
          isCreating: false,
          repository: _repository,
          plan: _selectedPlan,
        ),
      ),
    );

    if (result == true) {
      _loadPlans();
    }
  }

  Future<void> _createFocusArea() async {
    if (_selectedPlan == null) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DevelopmentFocusEditorPage(
          isCreating: true,
          planId: _selectedPlan!.planId!,
          repository: _repository,
        ),
      ),
    );

    if (result == true) {
      _loadFocusAreas(_selectedPlan!.planId!);
    }
  }

  Future<void> _editFocusArea(FocusArea focusArea) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DevelopmentFocusEditorPage(
          isCreating: false,
          repository: _repository,
          focusArea: focusArea,
          planId: _selectedPlan!.planId!,
        ),
      ),
    );

    if (result == true) {
      _loadFocusAreas(_selectedPlan!.planId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomNavigationDrawer(currentPage: 'developmentPlan'),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
        backgroundColor: AppColors.primary,
        title: const Text('Udviklingsplan', style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Ugentlig Plan'),
            Tab(text: 'Udviklingsfokus'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _createNewPlan,
            tooltip: 'Create New Plan',
          ),
          if (_selectedPlan != null)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _editPlan,
              tooltip: 'Edit Plan',
            ),
        ],
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _selectedPlan == null
                ? const Center(child: Text('Ingen udviklingsplan fundet', style: TextStyle(color: Colors.white)))
                : Column(
                    children: [
                      // Plan selector at the top, below app bar
                      if (_plans.length > 1)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          color: AppColors.primary.withOpacity(0.8),
                          child: Row(
                            children: [
                              const Text(
                                'Active Plan: ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(child: _buildPlanSelector()),
                            ],
                          ),
                        ),
                      // Tab content below selector
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildWeeklyScheduleTab(),
                            _buildDevelopmentFocus(),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
      floatingActionButton: _tabController.index == 1 && _selectedPlan != null
        ? FloatingActionButton(
            onPressed: _createFocusArea,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Tilføj Fokusområde',
          )
        : null,
    );
  }

  Widget _buildPlanSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DevelopmentPlan>(
          value: _selectedPlan,
          isExpanded: true,
          dropdownColor: AppColors.primary,
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white),
          hint: const Text('Select Plan', style: TextStyle(color: Colors.white70)),
          items: _plans.map((plan) {
            return DropdownMenuItem<DevelopmentPlan>(
              value: plan,
              child: Text(plan.title, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: (plan) {
            if (plan != null) {
              _onPlanSelected(plan);
            }
          },
        ),
      ),
    );
  }

  Widget _buildWeeklyScheduleTab() {
    return const Center(
      child: Text(
        'Weekly training schedule\ncoming soon!',
        style: TextStyle(color: Colors.white, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDevelopmentFocus() {
    if (_selectedPlan == null) {
      return const Center(child: Text('No development plan selected', style: TextStyle(color: Colors.white)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLongTermGoalsCard(),
          const SizedBox(height: 24),
          const Text(
            'Focus Areas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _focusAreas.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'No focus areas defined yet. Click the + button to add some!',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _focusAreas.length,
                  itemBuilder: (context, index) {
                    return _buildFocusAreaCard(_focusAreas[index]);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildLongTermGoalsCard() {
    return Card(
      color: AppColors.cardBackground.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Long-Term Goals',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedPlan?.longTermGoals ?? 'No long-term goals defined',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusAreaCard(FocusArea focusArea) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.cardBackground.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          focusArea.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              focusArea.description,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.white60),
                const SizedBox(width: 4),
                Text(
                  'Target: ${_formatDate(focusArea.targetDate)}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(focusArea.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(focusArea.status),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
              onPressed: () => _editFocusArea(focusArea),
              tooltip: 'Edit Focus Area',
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'not_started':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'in_progress':
        return 'In Progress';
      case 'not_started':
        return 'Not Started';
      default:
        return 'In Progress';
    }
  }
}
