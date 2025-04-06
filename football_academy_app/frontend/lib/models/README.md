# Player Stats Models

This document explains the player stats model structure used in the Copenhagen Academy App.

## PlayerStats Model

The `PlayerStats` model is used for displaying player skills in the radar chart and other visualizations. This model contains numerical ratings on a 0-100 scale.

```dart
class PlayerStats {
  final double pace;        // Derived from sprint test
  final double shooting;    // Derived from shooting test
  final double passing;     // Derived from passing test
  final double dribbling;   // Derived from dribbling test
  final double juggles;     // Derived from juggling test
  final double firstTouch;  // Derived from first touch test
  
  final double? overallRating;
  final DateTime? lastUpdated;
  final int? lastTestId;

  // Constructor, fromJson, toJson and empty() methods...
}
```

## PlayerTest Model

The `PlayerTest` model represents a specific skill test taken by a player. This model includes both:

1. Raw test values (actual measurements from tests)
2. Calculated ratings (converted to a 1-99 scale for display)
3. Legacy test values (for backward compatibility)

```dart
class PlayerTest {
  final int? id;
  final int? playerId;
  final DateTime? testDate;
  final String? position;
  
  // Raw test values
  final double? pace;
  final double? shooting;
  final double? passing;
  final double? dribbling;
  final double? juggles;
  final double? firstTouch;
  
  // Calculated ratings (1-99 scale)
  final int? paceRating;
  final int? shootingRating;
  final int? passingRating;
  final int? dribblingRating;
  final int? jugglesRating;
  final int? firstTouchRating;
  final int? overallRating;
  
  // Legacy test values for backward compatibility 
  final int? passingTest;
  final double? sprintTest;
  final int? firstTouchTest;
  final int? shootingTest;
  final int? jugglingTest;
  final double? dribblingTest;
  
  // Fields to track personal records
  final bool? isPassingRecord;
  final bool? isSprintRecord;
  final bool? isFirstTouchRecord;
  final bool? isShootingRecord;
  final bool? isJugglingRecord;
  final bool? isDribblingRecord;
  
  final String? notes;
  final int? recordedBy;
  
  // Constructor, fromJson, toJson methods...
  
  // Helper method to calculate overall rating when not provided
  int getOverallRating() { ... }
  
  // Method to check if a test broke any records
  bool brokeAnyRecord(String position) { ... }
}
```

## Conversion between models

The `PlayerStatsRadarChart` widget can display data from either model using a conversion method:

```dart
// Convert a PlayerTest to PlayerStats for the radar chart
PlayerStats _convertTestToStats(PlayerTest test) {
  return PlayerStats(
    pace: (test.paceRating ?? 50).toDouble(),
    shooting: (test.shootingRating ?? 50).toDouble(),
    passing: (test.passingRating ?? 50).toDouble(),
    dribbling: (test.dribblingRating ?? 50).toDouble(),
    juggles: (test.jugglesRating ?? 50).toDouble(),
    firstTouch: (test.firstTouchRating ?? 50).toDouble(),
    overallRating: (test.overallRating ?? test.getOverallRating()).toDouble(),
    lastUpdated: test.testDate,
    lastTestId: test.id,
  );
}
``` 