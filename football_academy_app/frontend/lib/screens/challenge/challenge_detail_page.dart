import 'package:flutter/material.dart';
import '../../models/challenge.dart';

class ChallengeDetailPage extends StatefulWidget {
  final Challenge challenge;

  const ChallengeDetailPage({
    Key? key,
    required this.challenge,
  }) : super(key: key);

  @override
  State<ChallengeDetailPage> createState() => _ChallengeDetailPageState();
}

class _ChallengeDetailPageState extends State<ChallengeDetailPage> {
  late Challenge _challenge;

  @override
  void initState() {
    super.initState();
    _challenge = widget.challenge;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_challenge.title),
      ),
      body: Container(), // TODO: Implement the body
    );
  }

  List<IconData> _getCategoryIcons() {
    switch (_challenge.category) {
      case ChallengeCategory.passing:
        return [Icons.sports_soccer, Icons.person, Icons.arrow_forward];
      case ChallengeCategory.shooting:
        return [Icons.sports_soccer, Icons.sports_handball, Icons.emergency];
      case ChallengeCategory.dribbling:
        return [Icons.sports_soccer, Icons.directions_run, Icons.change_circle];
      case ChallengeCategory.fitness:
        return [Icons.fitness_center, Icons.timer, Icons.monitor_heart];
      case ChallengeCategory.defense:
        return [Icons.shield, Icons.sports_soccer, Icons.block];
      case ChallengeCategory.goalkeeping:
        return [Icons.sports_soccer, Icons.catching_pokemon, Icons.ads_click];
      case ChallengeCategory.tactical:
        return [Icons.psychology, Icons.sports_soccer, Icons.schema];
      case ChallengeCategory.weekly:
        return [Icons.emoji_events, Icons.calendar_today, Icons.star];
      case ChallengeCategory.wallTouches:
        return [Icons.sports_soccer, Icons.grid_on, Icons.touch_app];
    }
  }

  Color _getCategoryColor() {
    switch (_challenge.category) {
      case ChallengeCategory.passing:
        return Colors.blue;
      case ChallengeCategory.shooting:
        return Colors.red;
      case ChallengeCategory.dribbling:
        return Colors.orange;
      case ChallengeCategory.fitness:
        return Colors.purple;
      case ChallengeCategory.defense:
        return Colors.indigo;
      case ChallengeCategory.goalkeeping:
        return Colors.teal;
      case ChallengeCategory.tactical:
        return Colors.brown;
      case ChallengeCategory.weekly:
        return Colors.amber;
      case ChallengeCategory.wallTouches:
        return Colors.green;
    }
  }
} 