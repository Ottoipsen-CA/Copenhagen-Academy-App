import 'package:flutter/material.dart';

class ChallengeDetailPage extends StatefulWidget {
  // ... (existing code)
}

class _ChallengeDetailPageState extends State<ChallengeDetailPage> {
  // ... (existing code)

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
        return [Icons.sports_soccer, Icons.wall, Icons.touch_app];
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

  // ... (rest of the existing code)
} 