import 'package:flutter/material.dart';
import '../../models/league_table_entry.dart';
import '../../models/user.dart';
import '../../models/challenge.dart';
import '../../services/league_table_service.dart';
import '../../services/challenge_service.dart';
import '../../widgets/navigation_drawer.dart';
import '../../widgets/fifa_player_card.dart';
import 'dart:math' as math;

// Need to define CardType enum as it's referenced but not defined anywhere
enum CardType {
  normal,
  totw,
  toty,
  future,
  hero,
  icon,
}

class LeagueTablePage extends StatefulWidget {
  const LeagueTablePage({super.key});

  @override
  State<LeagueTablePage> createState() => _LeagueTablePageState();
}

class _LeagueTablePageState extends State<LeagueTablePage> {
  List<LeagueTableEntry> _players = [];
  Challenge? _currentChallenge;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Add ScrollController
  final ScrollController _leagueTableScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _leagueTableScrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      debugPrint("LeagueTablePage: Loading data from API...");
      
      // First try to get the current active challenge
      Challenge? currentChallenge = await ChallengeService.getWeeklyChallenge();
      
      if (currentChallenge != null) {
        debugPrint("LeagueTablePage: Active challenge found with ID: ${currentChallenge.id}");
      } else {
        debugPrint("LeagueTablePage: No active challenge found");
      }
      
      // Get league table data
      List<LeagueTableEntry> players = [];
      
      try {
        if (currentChallenge != null) {
          debugPrint("LeagueTablePage: Fetching league table for challenge ${currentChallenge.id}");
          players = await LeagueTableService.getLeagueTableForChallenge(currentChallenge.id);
          debugPrint("LeagueTablePage: Retrieved ${players.length} entries for challenge");
        } else {
          debugPrint("LeagueTablePage: Fetching general league table");
          players = await LeagueTableService.getAllRankings();
          debugPrint("LeagueTablePage: Retrieved ${players.length} entries");
        }
        
        // Sort players by rank to ensure proper display order
        players.sort((a, b) => a.rank.compareTo(b.rank));
        
        setState(() {
          _currentChallenge = currentChallenge;
          _players = players;
          _isLoading = false;
        });
      } catch (e) {
        debugPrint("LeagueTablePage: Error fetching league table: $e");
        setState(() {
          _currentChallenge = currentChallenge; // Still set the challenge
          _errorMessage = 'Unable to load leaderboard data. Please try again later.';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("LeagueTablePage: Error in main data loading process: $e");
      setState(() {
        _errorMessage = 'Failed to load data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'League Table',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0B0057),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(
              Icons.menu,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: const CustomNavigationDrawer(currentPage: 'leagueTable'),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0057), Color(0xFF2D0A5F)],
          ),
        ),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              )
            : _players.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No league table data available',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _currentChallenge != null
                            ? 'No data for challenge: ${_currentChallenge!.title}'
                            : 'No active challenge found',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _buildLeagueTable(),
                ),
      ),
    );
  }
  
  Widget _buildLeagueTable() {
    // Get screen width to make responsive decisions
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
        return Scrollbar(
          controller: _leagueTableScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _leagueTableScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - AppBar().preferredSize.height,
          ),
            child: Column(
              children: [
                // Current Challenge Header
                if (_currentChallenge != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      color: Colors.amber.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: Colors.amber.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'CURRENT CHALLENGE',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentChallenge!.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentChallenge!.description,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Target: ${_currentChallenge!.targetValue} ${_currentChallenge!.unit}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                
                // League Table
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: Colors.white.withOpacity(0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: isSmallScreen 
                          ? _buildMobileLeagueTable() 
                          : _buildDesktopLeagueTable(),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentChallenge != null
                              ? 'League table shows rankings for the current challenge: ${_currentChallenge!.title}'
                              : 'Table shows best scores from completed challenges',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Add extra space at the bottom to ensure the gradient extends
              const SizedBox(height: 100),
              ],
            ),
          ),
      ),
    );
  }
  
  // Desktop-oriented table layout using Table widget
  Widget _buildDesktopLeagueTable() {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(40),    // Rank
        1: FlexColumnWidth(3),      // Player
        2: FixedColumnWidth(70),    // Score/Result
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          children: [
            _tableHeader('#'),
            _tableHeader('PLAYER'),
            _tableHeader('SCORE'),
          ],
        ),
        
        // Data rows - removing the take(20) limitation to show all entries
        for (var entry in _players)
          TableRow(
            decoration: BoxDecoration(
              color: entry.rank <= 3 
                  ? Colors.amber.withOpacity(0.1) 
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            children: [
              _tableCell(
                '${entry.rank}', 
                fontWeight: entry.rank <= 3 ? FontWeight.bold : FontWeight.normal,
                color: entry.rank <= 3 ? Colors.amber : Colors.white,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    _positionTag(entry.user.position ?? 'ST'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.user.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            entry.user.currentClub ?? '',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _scoreCell(entry.bestResult ?? 0, _currentChallenge?.unit ?? ''),
            ],
          ),
      ],
    );
  }
  
  // Mobile-oriented table layout using ListView for better visibility on small screens
  Widget _buildMobileLeagueTable() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: _tableHeader('#', textAlign: TextAlign.center),
              ),
              Expanded(
                child: _tableHeader('PLAYER', textAlign: TextAlign.left),
              ),
              SizedBox(
                width: 70,
                child: _tableHeader('SCORE', textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
        
        // Players list - removing the limitation of 20 items to show all entries
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _players.length,
          itemBuilder: (context, index) {
            final entry = _players[index];
            final isTopThree = entry.rank <= 3;
            
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                color: isTopThree ? Colors.amber.withOpacity(0.1) : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Rank
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      '${entry.rank}',
                      style: TextStyle(
                        color: isTopThree ? Colors.amber : Colors.white,
                        fontWeight: isTopThree ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  
                  // Player info
                  Expanded(
                    child: Row(
                      children: [
                        _positionTag(entry.user.position ?? 'ST'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.user.fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (entry.user.currentClub != null && entry.user.currentClub!.isNotEmpty)
                                Text(
                                  entry.user.currentClub!,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Score
                  Container(
                    width: 70,
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isTopThree 
                            ? Colors.amber.withOpacity(0.2) 
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isTopThree ? Colors.amber : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${entry.bestResult ?? 0}',
                        style: TextStyle(
                          color: isTopThree ? Colors.amber : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _tableHeader(String text, {TextAlign textAlign = TextAlign.center}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        textAlign: textAlign,
      ),
    );
  }
  
  Widget _tableCell(String text, {
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.white,
    TextAlign textAlign = TextAlign.center,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: fontWeight,
          fontSize: 14,
        ),
        textAlign: textAlign,
      ),
    );
  }
  
  Widget _ratingCell(int rating) {
    Color ratingColor = Colors.white;
    if (rating >= 85) {
      ratingColor = Colors.green;
    } else if (rating >= 80) {
      ratingColor = Colors.lightGreen;
    } else if (rating >= 75) {
      ratingColor = Colors.amber;
    } else if (rating >= 70) {
      ratingColor = Colors.orange;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: ratingColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$rating',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: ratingColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _positionTag(String position) {
    Color bgColor;
    if (position == 'GK') {
      bgColor = Colors.yellow;
    } else if (['CB', 'RB', 'LB'].contains(position)) {
      bgColor = Colors.green;
    } else if (['CDM', 'CM', 'CAM', 'LW', 'RW'].contains(position)) {
      bgColor = Colors.lightBlue;
    } else {
      bgColor = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        position,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
  
  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey.shade400;
    if (rank == 3) return Colors.brown.shade300;
    return Colors.purple.shade700;
  }
  
  CardType _getCardType(int rating) {
    if (rating >= 95) {
      return CardType.icon;
    } else if (rating >= 90) {
      return CardType.toty;
    } else if (rating >= 87) {
      return CardType.totw;
    } else if (rating >= 85) {
      return CardType.future;
    } else if (rating >= 83) {
      return CardType.hero;
    } else {
      return CardType.normal;
    }
  }

  // Add a new helper widget for the score cell
  Widget _scoreCell(num score, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$score ${unit.isNotEmpty ? unit : ''}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
} 