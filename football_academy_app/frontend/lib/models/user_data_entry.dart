import 'package:hive/hive.dart';

/// UserDataEntry model for storing numeric data with timestamp and category
class UserDataEntry {
  final String userId;
  double value;
  final String category;
  DateTime timestamp;
  String? notes;
  int? key;

  UserDataEntry({
    required this.userId,
    required this.value,
    required this.category,
    required this.timestamp,
    this.notes,
    this.key,
  });
}

/// Manually created adapter for Hive
class UserDataEntryAdapter extends TypeAdapter<UserDataEntry> {
  @override
  final typeId = 1;

  @override
  UserDataEntry read(BinaryReader reader) {
    return UserDataEntry(
      userId: reader.read(),
      value: reader.read(),
      category: reader.read(),
      timestamp: reader.read(),
      notes: reader.read(),
      key: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, UserDataEntry obj) {
    writer.write(obj.userId);
    writer.write(obj.value);
    writer.write(obj.category);
    writer.write(obj.timestamp);
    writer.write(obj.notes);
    writer.write(obj.key);
  }
} 