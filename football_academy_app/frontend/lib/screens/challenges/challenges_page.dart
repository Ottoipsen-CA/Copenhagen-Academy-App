import 'package:flutter/material.dart';
import '../../models/challenge.dart';
import '../../services/challenge_service.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/navigation_drawer.dart';
import 'challenge_detail_page.dart';

class ChallengesPage extends StatefulWidget {
  static const String routeName = '/challenges';
  
  const ChallengesPage({Key? key}) : super(key: key);

  @override
  _ChallengesPageState createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Challenge>> _challengesFuture;
  late Future<List<UserChallenge>> _userChallengesFuture;
  late Future<Challenge?> _weeklyChallengeFuture;
  
  bool _isLoading = false;
  List<Challenge> _challenges = [];
  List<Challenge> _filteredChallenges = [];
  List<UserChallenge> _userChallenges = [];
  
  final List<ChallengeCategory> _categories = [
    ChallengeCategory.passing,
    ChallengeCategory.shooting,
    ChallengeCategory.dribbling,
    ChallengeCategory.fitness,
    ChallengeCategory.defense,
    ChallengeCategory.goalkeeping,
    ChallengeCategory.tactical,
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadChallenges();
    
    // Initialize futures
    _challengesFuture = ChallengeService.getAllChallengesWithStatus();
    _userChallengesFuture = ChallengeService.getUserChallenges();
    _weeklyChallengeFuture = ChallengeService.getWeeklyChallenge();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadChallenges() async {
    try {
      _isLoading = true;
      setState(() {});
      
      print('Loading challenges from API...');
      
      // Get challenges from service
      final challenges = await ChallengeService.getAllChallengesWithStatus();
      final userChallenges = await ChallengeService.getUserChallenges();
      
      print('Got ${challenges.length} challenges and ${userChallenges.length} user challenges');
      
      // TEMPORARY FIX: Force all challenges to be available
      final updatedUserChallenges = userChallenges.map((uc) {
        if (uc.status == ChallengeStatus.locked) {
          print('Forcing challenge ${uc.challengeId} from LOCKED to AVAILABLE');
          return uc.copyWith(status: ChallengeStatus.available);
        }
        return uc;
      }).toList();
      
      // Make sure every challenge has an associated user challenge that is available
      final List<UserChallenge> finalUserChallenges = [...updatedUserChallenges];
      for (final challenge in challenges) {
        final existingIndex = finalUserChallenges.indexWhere((uc) => uc.challengeId == challenge.id);
        if (existingIndex == -1) {
          print('Creating new AVAILABLE status for challenge ${challenge.id}');
          finalUserChallenges.add(UserChallenge(
            challengeId: challenge.id,
            status: ChallengeStatus.available, // Force available
            startedAt: DateTime.now(),
          ));
        }
      }
      
      // Save updated user challenges
      await ChallengeService.saveUserChallenges(finalUserChallenges);
      
      setState(() {
        _challenges = challenges;
        _userChallenges = finalUserChallenges;
        _filteredChallenges = List.from(_challenges);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading challenges: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load challenges: $e')),
        );
        _isLoading = false;
        setState(() {});
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Challenges',
      ),
      drawer: const CustomNavigationDrawer(currentPage: 'challenges'),
      body: GradientBackground(
        child: FutureBuilder<List<Object?>>(
          future: Future.wait([
            _challengesFuture,
            _userChallengesFuture,
            _weeklyChallengeFuture
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading challenges: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }
            
            if (!snapshot.hasData) {
              return const Center(
                child: Text(
                  'No challenges found',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            
            final challenges = snapshot.data![0] as List<Challenge>;
            final userChallenges = snapshot.data![1] as List<UserChallenge>;
            final weeklyChallenge = snapshot.data![2] as Challenge?;
            
            return _buildChallengesContent(
              challenges, 
              userChallenges, 
              weeklyChallenge
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadChallenges,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.refresh),
      ),
    );
  }
  
  Widget _buildChallengesContent(
    List<Challenge> challenges,
    List<UserChallenge> userChallenges,
    Challenge? weeklyChallenge,
  ) {
    return Column(
      children: [
        // Weekly challenge section
        if (weeklyChallenge != null) 
          _buildWeeklyChallenge(weeklyChallenge, userChallenges),
        
        // Tab bar for challenge categories
        Container(
          color: AppColors.cardBackground.withOpacity(0.3),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: AppColors.primary,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: _categories.map((category) {
              return Tab(text: category.displayName);
            }).toList(),
          ),
        ),
        
        // Challenge lists by category
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _categories.map((category) {
              return _buildChallengeList(
                challenges.where((c) => c.category == category).toList(),
                userChallenges,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildWeeklyChallenge(
    Challenge weeklyChallenge,
    List<UserChallenge> userChallenges,
  ) {
    // Find user's progress on this challenge
    final userChallenge = userChallenges.firstWhere(
      (uc) => uc.challengeId == weeklyChallenge.id,
      orElse: () => UserChallenge(
        challengeId: weeklyChallenge.id,
        status: ChallengeStatus.available,
        startedAt: DateTime.now(),
      ),
    );
    
    final progress = userChallenge.currentValue / weeklyChallenge.targetValue;
    final isCompleted = userChallenge.status == ChallengeStatus.completed;
    final statusColor = isCompleted ? Colors.green : AppColors.primary;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChallengeDetailPage(
                challenge: weeklyChallenge,
                userChallenge: userChallenge,
              ),
            ),
          ).then((_) => _loadChallenges());
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.8),
                AppColors.primary.withOpacity(0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'WEEKLY CHALLENGE',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (weeklyChallenge.deadline != null) ...[
                    Text(
                      'Ends in ${_getRemainingDays(weeklyChallenge.deadline!)} days',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                weeklyChallenge.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                weeklyChallenge.description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              // Progress indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress: ${userChallenge.currentValue}/${weeklyChallenge.targetValue} ${weeklyChallenge.unit}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isCompleted ? 'COMPLETED' : '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChallengeDetailPage(
                          challenge: weeklyChallenge,
                          userChallenge: userChallenge,
                        ),
                      ),
                    ).then((_) => _loadChallenges());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    isCompleted ? 'View Details' : 'Record Progress',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildChallengeList(
    List<Challenge> challenges,
    List<UserChallenge> userChallenges,
  ) {
    // Sort challenges by level
    challenges.sort((a, b) => a.level.compareTo(b.level));
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        
        // Find user's progress on this challenge
        final userChallenge = userChallenges.firstWhere(
          (uc) => uc.challengeId == challenge.id,
          orElse: () => UserChallenge(
            challengeId: challenge.id,
            status: ChallengeStatus.locked,
            startedAt: DateTime.now(),
          ),
        );
        
        return _buildChallengeCard(challenge, userChallenge);
      },
    );
  }
  
  Widget _buildChallengeCard(Challenge challenge, UserChallenge userChallenge) {
    // OVERRIDE: Force all challenges to be available regardless of status
    final isLocked = false; // All challenges should be available, never locked
    final isCompleted = userChallenge.status == ChallengeStatus.completed;
    final isAvailable = !isCompleted; // If not completed, it's available
    final isInProgress = false; // We're not using in-progress status for this version
    
    Color cardColor;
    IconData statusIcon;
    String statusText;
    
    if (isLocked) { // This block will never execute due to override above
      cardColor = Colors.grey;
      statusIcon = Icons.lock;
      statusText = 'LOCKED';
    } else if (isCompleted) {
      cardColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'COMPLETED';
    } else if (isInProgress) {
      cardColor = AppColors.primary;
      statusIcon = Icons.play_circle_filled;
      statusText = 'IN PROGRESS';
    } else { // available
      cardColor = Colors.amber;
      statusIcon = Icons.stars;
      statusText = 'AVAILABLE';
    }
    
    // Calculate progress if in progress or completed
    double progress = 0.0;
    if (isInProgress || isCompleted) {
      progress = userChallenge.currentValue / challenge.targetValue;
      progress = progress.clamp(0.0, 1.0);
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        // Remove the isLocked check to make all challenges tappable
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChallengeDetailPage(
                challenge: challenge,
                userChallenge: userChallenge,
              ),
            ),
          ).then((_) => _loadChallenges());
        },
        // Remove the opacity change for locked challenges
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cardColor.withOpacity(0.7),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      statusIcon,
                      color: cardColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: cardColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Level ${challenge.level}',
                        style: TextStyle(
                          color: cardColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      challenge.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Progress bar for in-progress challenges
                    if (isInProgress || isCompleted) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress: ${userChallenge.currentValue}/${challenge.targetValue} ${challenge.unit}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              color: cardColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                        ),
                      ),
                    ],
                    
                    // Locked message
                    if (isLocked) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.white.withOpacity(0.7),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Complete the previous level challenges to unlock',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    // Action button
                    if (!isLocked) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChallengeDetailPage(
                                  challenge: challenge,
                                  userChallenge: userChallenge,
                                ),
                              ),
                            ).then((_) => _loadChallenges());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cardColor,
                            foregroundColor: isCompleted ? Colors.white : Colors.black87,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            isAvailable 
                                ? 'Start Challenge' 
                                : isCompleted 
                                    ? 'View Details' 
                                    : 'Continue',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  int _getRemainingDays(DateTime deadline) {
    final now = DateTime.now();
    return deadline.difference(now).inDays + 1;
  }
} 