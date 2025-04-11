/// Configuration for feature flags to enable/disable specific app features
/// 
/// This centralized file allows easy toggling of features across the app.
/// Set a flag to false to completely disable the corresponding feature.
class FeatureFlags {
  // Core features
  static const bool authEnabled = true;     // Authentication (should always be true)
  
  // Challenge and competition features
  static const bool challengesEnabled = true;       // Challenges feature
  static const bool badgesEnabled = true;           // Achievement badges
  static const bool leagueTableEnabled = true;      // League table/rankings
  
  // Player features
  static const bool playerStatsEnabled = false;     // Player statistics
  static const bool playerTestsEnabled = true;      // Physical tests
} 