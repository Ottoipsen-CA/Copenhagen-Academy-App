import 'dart:convert';
import 'user.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['sender_id'],
      text: json['text'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
    };
  }
}

class ChatConversation {
  final String id;
  final List<String> participantIds;
  final List<ChatMessage> messages;
  final DateTime lastUpdated;
  final String? lastMessagePreview;

  ChatConversation({
    required this.id,
    required this.participantIds,
    required this.messages,
    required this.lastUpdated,
    this.lastMessagePreview,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'],
      participantIds: List<String>.from(json['participant_ids']),
      messages: (json['messages'] as List)
          .map((m) => ChatMessage.fromJson(m))
          .toList(),
      lastUpdated: DateTime.parse(json['last_updated']),
      lastMessagePreview: json['last_message_preview'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participant_ids': participantIds,
      'messages': messages.map((m) => m.toJson()).toList(),
      'last_updated': lastUpdated.toIso8601String(),
      'last_message_preview': lastMessagePreview,
    };
  }

  String getOtherParticipantId(String currentUserId) {
    return participantIds.firstWhere((id) => id != currentUserId);
  }
} 