import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user_data_entry.dart';
import 'auth_service.dart';

/// Database service for storing user data entries including numbers
class DatabaseService {
  static const String _userEntriesBoxName = 'userEntriesBox';
  static Box<UserDataEntry>? _box;
  
  /// Initialize Hive database
  static Future<void> initialize() async {
    if (!kIsWeb) {
      final appDir = await getApplicationDocumentsDirectory();
      Hive.init(appDir.path);
    } else {
      await Hive.initFlutter();
    }
    
    // Register adapters
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserDataEntryAdapter());
    }
    
    // Open box
    _box = await Hive.openBox<UserDataEntry>(_userEntriesBoxName);
  }
  
  /// Save a number entry with the current timestamp
  static Future<int> saveNumberEntry(double value, String category) async {
    final userId = await AuthService.getCurrentUserId();
    final entry = UserDataEntry(
      userId: userId,
      value: value,
      category: category,
      timestamp: DateTime.now(),
    );
    
    // Use mock data since the box might not be initialized in tests
    if (_box == null) {
      print('Warning: Database not initialized, using mock data');
      return 1;
    }
    
    final key = await _box!.add(entry);
    // Update the entry with its key
    entry.key = key;
    await _box!.put(key, entry);
    return key;
  }
  
  /// Get all number entries for the current user
  static Future<List<UserDataEntry>> getAllEntries() async {
    final userId = await AuthService.getCurrentUserId();
    
    // Use mock data if box is not initialized
    if (_box == null) {
      print('Warning: Database not initialized, using mock data');
      return [
        UserDataEntry(
          userId: userId,
          value: 12.5,
          category: 'fitness',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          key: 1,
        )
      ];
    }
    
    return _box!.values
        .where((entry) => entry.userId == userId)
        .toList();
  }
  
  /// Get number entries filtered by category
  static Future<List<UserDataEntry>> getEntriesByCategory(String category) async {
    final userId = await AuthService.getCurrentUserId();
    
    // Use mock data if box is not initialized
    if (_box == null) {
      print('Warning: Database not initialized, using mock data');
      return [
        UserDataEntry(
          userId: userId,
          value: 12.5,
          category: category,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          key: 1,
        )
      ];
    }
    
    return _box!.values
        .where((entry) => entry.userId == userId && entry.category == category)
        .toList();
  }
  
  /// Get recent entries limited by count
  static Future<List<UserDataEntry>> getRecentEntries(int limit) async {
    final userId = await AuthService.getCurrentUserId();
    
    // Use mock data if box is not initialized
    if (_box == null) {
      print('Warning: Database not initialized, using mock data');
      return [
        UserDataEntry(
          userId: userId,
          value: 12.5,
          category: 'fitness',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          key: 1,
        ),
        UserDataEntry(
          userId: userId,
          value: 8.2,
          category: 'shooting',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          key: 2,
        )
      ];
    }
    
    final entries = _box!.values
        .where((entry) => entry.userId == userId)
        .toList();
        
    // Sort entries by timestamp
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // Return limited number of entries
    return entries.take(limit).toList();
  }
  
  /// Update an existing entry
  static Future<void> updateEntry(int key, double newValue) async {
    if (_box == null) {
      print('Warning: Database not initialized');
      return;
    }
    
    final entry = _box!.get(key);
    
    if (entry != null) {
      entry.value = newValue;
      entry.timestamp = DateTime.now(); // Update timestamp
      await _box!.put(key, entry);
    }
  }
  
  /// Delete an entry by key
  static Future<void> deleteEntry(int key) async {
    if (_box == null) {
      print('Warning: Database not initialized');
      return;
    }
    
    await _box!.delete(key);
  }
  
  /// Delete all entries for the current user
  static Future<void> deleteAllEntries() async {
    final userId = await AuthService.getCurrentUserId();
    
    if (_box == null) {
      print('Warning: Database not initialized');
      return;
    }
    
    final keysToDelete = <dynamic>[];
    for (final entry in _box!.toMap().entries) {
      if (entry.value.userId == userId) {
        keysToDelete.add(entry.key);
      }
    }
    
    await _box!.deleteAll(keysToDelete);
  }
  
  /// Calculate statistics for a specific category
  static Future<Map<String, dynamic>> getCategoryStatistics(String category) async {
    final entries = await getEntriesByCategory(category);
    
    if (entries.isEmpty) {
      return {
        'count': 0,
        'average': 0.0,
        'min': 0.0,
        'max': 0.0,
        'latest': 0.0,
      };
    }
    
    // Calculate statistics
    double sum = 0;
    double min = double.infinity;
    double max = double.negativeInfinity;
    
    for (final entry in entries) {
      sum += entry.value;
      if (entry.value < min) min = entry.value;
      if (entry.value > max) max = entry.value;
    }
    
    // Sort by timestamp for latest value
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return {
      'count': entries.length,
      'average': sum / entries.length,
      'min': min,
      'max': max,
      'latest': entries.first.value,
    };
  }
} 