import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/development_plan.dart';
import '../../repositories/development_plan_repository.dart';
import '../../services/api_service.dart';
import '../../theme/colors.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/navigation_drawer.dart';
import 'development_plan_editor_page.dart';
import 'weekly_training_schedule_page.dart';
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
    _tabController.addListener(() {
      setState(() {});
    });
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
      
      if (mounted) {
        // Sort plans by created_at date, most recent first
        plans.sort((a, b) {
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        
        // Select the first (most recent) plan if available
        final mostRecentPlan = plans.isNotEmpty ? plans.first : null;
        
        setState(() {
          _plans = plans;
          _selectedPlan = mostRecentPlan;
          _isLoading = false;
        });
        
        // Load focus areas for the selected plan
        if (mostRecentPlan != null) {
          _loadFocusAreas(mostRecentPlan.planId!);
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
    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vælg venligst en udviklingsplan først'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
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

  Future<void> _deleteFocusArea(FocusArea focusArea) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Slet fokusområde', style: TextStyle(color: Colors.white)),
        content: Text('Er du sikker på, at du vil slette "${focusArea.title}"?', 
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
        await _repository.deleteFocusArea(focusArea.developmentPlanId, focusArea.focusAreaId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fokusområde slettet')),
          );
          // Reload focus areas
          _loadFocusAreas(_selectedPlan!.planId!);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fejl ved sletning: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _deletePlan() async {
    if (_selectedPlan == null) return;
    
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Slet udviklingsplan', style: TextStyle(color: Colors.white)),
        content: Text('Er du sikker på, at du vil slette "${_selectedPlan!.title}"? Dette vil også slette alle tilhørende fokusområder.', 
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
        await _repository.delete(_selectedPlan!.planId.toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Udviklingsplan slettet')),
          );
          // Reload plans
          _loadPlans();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fejl ved sletning: ${e.toString()}')),
          );
        }
      }
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
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _plans.isEmpty
                ? const Center(child: Text('Ingen udviklingsplaner fundet. Klik på + for at oprette en ny plan.', 
                    style: TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Weekly Training Schedule View
                      const WeeklyTrainingSchedulePage(),
                      
                      // Development Focus View
                      Column(
                        children: [
                          // Plan selector for the Development Focus tab
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            color: AppColors.primary.withOpacity(0.8),
                            child: Row(
                              children: [
                                // Plan selector
                                Expanded(child: _buildPlanSelector()),
                                
                                // Action buttons
                                IconButton(
                                  icon: const Icon(Icons.add, color: Colors.white),
                                  onPressed: _createNewPlan,
                                  tooltip: 'Opret ny plan',
                                ),
                              ],
                            ),
                          ),
                          // Development focus content
                          Expanded(child: _buildDevelopmentFocus()),
                        ],
                      ),
                    ],
                  ),
      ),
      floatingActionButton: _tabController.index == 1 && !_isLoading && !_plans.isEmpty
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
          hint: const Text('Vælg plan', style: TextStyle(color: Colors.white70)),
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

  Widget _buildDevelopmentFocus() {
    if (_selectedPlan == null && _plans.isNotEmpty) {
      // If we have plans but none selected, automatically select the first one
      Future.microtask(() {
        setState(() {
          _selectedPlan = _plans.first;
        });
        _loadFocusAreas(_plans.first.planId!);
      });
      
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    
    if (_selectedPlan == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Vælg en udviklingsplan for at se fokusområder, eller opret en ny plan ved at klikke på + knappen øverst.',
            style: TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Highlighted long-term goals section with distinct styling
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.8),
                  AppColors.primary.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag_outlined, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    const Text(
                      'Langsigtede Mål',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.white),
                      onPressed: _editPlan,
                      tooltip: 'Rediger mål',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white),
                      onPressed: _deletePlan,
                      tooltip: 'Slet plan',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedPlan?.longTermGoals ?? 'Ingen langsigtede mål defineret',
                  style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                ),
              ],
            ),
          ),
          
          // Focus areas header
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
            child: Row(
              children: [
                const Icon(Icons.center_focus_strong, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Fokusområder',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_focusAreas.isNotEmpty)
                  Text(
                    '${_focusAreas.length} ${_focusAreas.length == 1 ? 'område' : 'områder'}',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                  ),
              ],
            ),
          ),
          
          // Focus areas list
          _focusAreas.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.add_circle_outline, color: Colors.white.withOpacity(0.7), size: 40),
                        const SizedBox(height: 16),
                        const Text(
                          'Ingen fokusområder defineret endnu. Klik på + knappen for at tilføje!',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
                  'Mål: ${_formatDate(focusArea.targetDate)}',
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
              tooltip: 'Rediger fokusområde',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white70, size: 20),
              onPressed: () => _deleteFocusArea(focusArea),
              tooltip: 'Slet fokusområde',
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
        return 'Gennemført';
      case 'in_progress':
        return 'I gang';
      case 'not_started':
        return 'Ikke påbegyndt';
      default:
        return 'I gang';
    }
  }
}
