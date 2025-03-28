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
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _loadChallenges() {
    // Initialize user challenges if needed
    ChallengeService.initializeUserChallenges();
    
    // Load challenges data
    setState(() {
      _challengesFuture = ChallengeService.getAllChallenges();
      _userChallengesFuture = ChallengeService.getUserChallenges();
      _weeklyChallengeFuture = ChallengeService.getWeeklyChallenge();
    });
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
    final isLocked = userChallenge.status == ChallengeStatus.locked;
    final isCompleted = userChallenge.status == ChallengeStatus.completed;
    final isAvailable = userChallenge.status == ChallengeStatus.available;
    final isInProgress = userChallenge.status == ChallengeStatus.inProgress;
    
    Color cardColor;
    IconData statusIcon;
    String statusText;
    
    if (isLocked) {
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
    
    // Calculate progress if in progress
    double progress = 0.0;
    if (isInProgress || isCompleted) {
      progress = userChallenge.currentValue / challenge.targetValue;
      progress = progress.clamp(0.0, 1.0);
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: isLocked ? null : () {
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
        child: Opacity(
          opacity: isLocked ? 0.6 : 1.0,
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
      ),
    );
  }
  
  int _getRemainingDays(DateTime deadline) {
    final now = DateTime.now();
    return deadline.difference(now).inDays + 1;
  }
} 