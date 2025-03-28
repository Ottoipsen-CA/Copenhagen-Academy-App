import 'dart:convert';

enum FriendshipStatus {
  pending,
  accepted,
  rejected,
  blocked
}

class Friendship {
  final String id;
  final String requesterId;
  final String receiverId;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Friendship({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'],
      requesterId: json['requester_id'],
      receiverId: json['receiver_id'],
      status: FriendshipStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'], 
        orElse: () => FriendshipStatus.pending
      ),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requester_id': requesterId,
      'receiver_id': receiverId,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool isUserInvolved(String userId) {
    return requesterId == userId || receiverId == userId;
  }

  String getOtherUserId(String currentUserId) {
    return requesterId == currentUserId ? receiverId : requesterId;
  }

  bool isPending() => status == FriendshipStatus.pending;
  bool isAccepted() => status == FriendshipStatus.accepted;
  bool isRejected() => status == FriendshipStatus.rejected;
  bool isBlocked() => status == FriendshipStatus.blocked;
} 