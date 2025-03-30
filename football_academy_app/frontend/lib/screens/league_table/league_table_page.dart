import 'package:flutter/material.dart';
import '../../models/league_table_entry.dart';
import '../../models/user.dart';
import '../../services/league_table_service.dart';
import '../../widgets/navigation_drawer.dart';
import '../../widgets/fifa_player_card.dart';
import 'dart:math' as math;

enum ViewMode {
  leagueTable,
  players
}

class LeagueTablePage extends StatefulWidget {
  const LeagueTablePage({super.key});

  @override
  State<LeagueTablePage> createState() => _LeagueTablePageState();
}

class _LeagueTablePageState extends State<LeagueTablePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ViewMode _viewMode = ViewMode.leagueTable;
  String _selectedPosition = 'All';
  List<LeagueTableEntry> _players = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Position filter options
  final List<String> _positions = [
    'All', 'GK', 'Defenders', 'Midfielders', 'Strikers'
  ];

  // Position mappings for filtering
  final Map<String, List<String>> _positionMappings = {
    'GK': ['GK'],
    'Defenders': ['CB', 'RB', 'LB'],
    'Midfielders': ['CDM', 'CM', 'CAM', 'LW', 'RW'],
    'Strikers': ['ST']
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }
  
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _viewMode = ViewMode.leagueTable;
            break;
          case 1:
            _viewMode = ViewMode.players;
            break;
        }
        _loadData();
      });
    }
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      List<LeagueTableEntry> players;
      
      switch (_viewMode) {
        case ViewMode.leagueTable:
          players = await LeagueTableService.getAllRankings();
          break;
        case ViewMode.players:
          if (_selectedPosition == 'All') {
            players = await LeagueTableService.getAllRankings();
          } else {
            players = await LeagueTableService.getAllRankings();
            final positionList = _positionMappings[_selectedPosition] ?? [];
            players = players.where((player) => positionList.contains(player.user.position)).toList();
          }
          break;
      }
      
      setState(() {
        _players = players;
        _isLoading = false;
      });
    } catch (e) {
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
        title: const Text('League Table'),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'LEAGUE TABLE'),
            Tab(text: 'PLAYERS'),
          ],
        ),
      ),
      drawer: const CustomNavigationDrawer(currentPage: 'leagueTable'),
      body: Container(
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
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white),
                ),
              )
            : _buildContent(),
      ),
    );
  }
  
  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildLeagueTableTab(),
        _buildPlayersTab(),
      ],
    );
  }
  
  Widget _buildLeagueTableTab() {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: Colors.white.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Table(
                    columnWidths: const {
                      0: FixedColumnWidth(40),    // Rank
                      1: FlexColumnWidth(3),      // Player
                      2: FixedColumnWidth(30),    // MP
                      3: FixedColumnWidth(30),    // W
                      4: FixedColumnWidth(30),    // D
                      5: FixedColumnWidth(30),    // L
                      6: FixedColumnWidth(50),    // Points
                      7: FixedColumnWidth(60),    // Rating
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
                          _tableHeader('MP'),
                          _tableHeader('W'),
                          _tableHeader('D'),
                          _tableHeader('L'),
                          _tableHeader('PTS'),
                          _tableHeader('RATING'),
                        ],
                      ),
                      
                      // Data rows
                      for (var entry in _players.take(20))
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
                            _tableCell('${entry.matchesPlayed}'),
                            _tableCell('${entry.wins}'),
                            _tableCell('${entry.draws}'),
                            _tableCell('${entry.losses}'),
                            _tableCell(
                              '${entry.totalPoints}',
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            _ratingCell(entry.stats.overallRating.toInt()),
                          ],
                        ),
                    ],
                  ),
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
                  Text(
                    'Points are calculated from matches and challenges',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
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
  
  Widget _buildPlayersTab() {
    return Column(
      children: [
        // Position filter
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _positions.map((position) {
              final isSelected = position == _selectedPosition;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  selected: isSelected,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  selectedColor: const Color(0xFF8A2BE2),
                  checkmarkColor: Colors.white,
                  label: Text(
                    position,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedPosition = position;
                      _loadData();
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
        
        // Player cards
        Expanded(
          child: _players.isEmpty
            ? Center(
                child: Text(
                  'No players found for $_selectedPosition position',
                  style: const TextStyle(color: Colors.white),
                ),
              )
            : Scrollbar(
                thickness: 8,
                radius: const Radius.circular(4),
                thumbVisibility: true,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 0.55,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _players.length,
                  itemBuilder: (context, index) {
                    final player = _players[index];
                    return SizedBox(
                      height: 180, // Smaller height
                      child: FifaPlayerCard(
                        playerName: player.user.fullName,
                        position: player.user.position ?? 'ST',
                        stats: player.stats,
                        rating: player.stats.overallRating.toInt(),
                        nationality: '🇦🇺', // Default flag
                        playerImageUrl: 'https://raw.githubusercontent.com/ottoipsen/football_academy_assets/main/player_photos/player_photo.jpg',
                        cardType: _getCardType(player.stats.overallRating.toInt()),
                      ),
                    );
                  },
                ),
              ),
        ),
      ],
    );
  }
  
  // Helper Widgets
  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _tableCell(String text, {
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: fontWeight,
        ),
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
    // Position colors
    final Map<String, Color> positionColors = {
      'GK': Colors.amber,
      'CB': Colors.lightGreen,
      'RB': Colors.lightGreen,
      'LB': Colors.lightGreen,
      'CDM': Colors.cyanAccent,
      'CM': Colors.cyanAccent,
      'CAM': Colors.orangeAccent,
      'LW': Colors.redAccent,
      'RW': Colors.redAccent,
      'ST': Colors.redAccent,
    };
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (positionColors[position] ?? Colors.purple).withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        position,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
  
  Color _getLeaderColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.blueGrey;
      case 2:
        return Colors.brown;
      default:
        return Colors.purple;
    }
  }
  
  CardType _getCardType(int rating) {
    // Icon card for legendary players
    if (rating >= 95) {
      return CardType.icon;
    } 
    // Team of the Year for very high-rated
    else if (rating >= 90) {
      return CardType.toty;
    } 
    // Record breaker (let's use a threshold close to but below TOTY)
    else if (rating >= 88) {
      return CardType.record_breaker;
    }
    // Team of the Week 
    else if (rating >= 85) {
      return CardType.totw;
    } 
    // Ones to Watch (slightly below TOTW)
    else if (rating >= 83) {
      return CardType.ones_to_watch;
    }
    // Future Stars
    else if (rating >= 80) {
      return CardType.future;
    } 
    // Hero cards
    else if (rating >= 75) {
      return CardType.hero;
    } 
    // Normal card
    else {
      return CardType.normal;
    }
  }
} 