import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/chat.dart';
import '../models/friendship.dart';
import '../models/user.dart';
import 'auth_service.dart';

class ChatService {
  static const String _conversationsKey = 'conversations';
  static const String _friendshipsKey = 'friendships';
  
  static final Uuid _uuid = Uuid();
  
  // Get all conversations for the current user
  static Future<List<ChatConversation>> getConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final conversationsJson = prefs.getStringList(_conversationsKey);
    
    if (conversationsJson != null) {
      try {
        return conversationsJson
            .map((json) => ChatConversation.fromJson(jsonDecode(json)))
            .toList();
      } catch (e) {
        print('Error loading conversations: $e');
      }
    }
    
    // Return empty list if none exist
    return [];
  }
  
  // Get all friendships for the current user
  static Future<List<Friendship>> getFriendships() async {
    final prefs = await SharedPreferences.getInstance();
    final friendshipsJson = prefs.getStringList(_friendshipsKey);
    
    if (friendshipsJson != null) {
      try {
        return friendshipsJson
            .map((json) => Friendship.fromJson(jsonDecode(json)))
            .toList();
      } catch (e) {
        print('Error loading friendships: $e');
      }
    }
    
    // Return empty list if none exist
    return [];
  }
  
  // Save conversations
  static Future<void> saveConversations(List<ChatConversation> conversations) async {
    final prefs = await SharedPreferences.getInstance();
    final conversationsJson = conversations
        .map((conversation) => jsonEncode(conversation.toJson()))
        .toList();
    
    await prefs.setStringList(_conversationsKey, conversationsJson);
  }
  
  // Save friendships
  static Future<void> saveFriendships(List<Friendship> friendships) async {
    final prefs = await SharedPreferences.getInstance();
    final friendshipsJson = friendships
        .map((friendship) => jsonEncode(friendship.toJson()))
        .toList();
    
    await prefs.setStringList(_friendshipsKey, friendshipsJson);
  }
  
  // Get conversation by ID
  static Future<ChatConversation?> getConversationById(String id) async {
    final conversations = await getConversations();
    try {
      return conversations.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Get conversation with a specific user
  static Future<ChatConversation?> getConversationWithUser(String userId) async {
    final conversations = await getConversations();
    final currentUserId = await AuthService.getCurrentUserId();
    
    try {
      return conversations.firstWhere((c) => 
        c.participantIds.contains(userId) && 
        c.participantIds.contains(currentUserId)
      );
    } catch (e) {
      return null;
    }
  }
  
  // Create a new conversation
  static Future<ChatConversation> createConversation(String otherUserId) async {
    final conversations = await getConversations();
    final currentUserId = await AuthService.getCurrentUserId();
    
    // Check if conversation already exists
    final existingConversation = await getConversationWithUser(otherUserId);
    if (existingConversation != null) {
      return existingConversation;
    }
    
    // Create new conversation
    final newConversation = ChatConversation(
      id: _uuid.v4(),
      participantIds: [currentUserId, otherUserId],
      messages: [],
      lastUpdated: DateTime.now(),
    );
    
    conversations.add(newConversation);
    await saveConversations(conversations);
    
    return newConversation;
  }
  
  // Send a message
  static Future<ChatMessage> sendMessage(String conversationId, String text) async {
    final conversations = await getConversations();
    final currentUserId = await AuthService.getCurrentUserId();
    
    final index = conversations.indexWhere((c) => c.id == conversationId);
    if (index < 0) {
      throw Exception('Conversation not found');
    }
    
    // Create new message
    final message = ChatMessage(
      id: _uuid.v4(),
      senderId: currentUserId,
      text: text,
      timestamp: DateTime.now(),
    );
    
    // Update conversation
    final conversation = conversations[index];
    final messages = List<ChatMessage>.from(conversation.messages)..add(message);
    
    conversations[index] = ChatConversation(
      id: conversation.id,
      participantIds: conversation.participantIds,
      messages: messages,
      lastUpdated: DateTime.now(),
      lastMessagePreview: text.length > 30 ? '${text.substring(0, 27)}...' : text,
    );
    
    await saveConversations(conversations);
    
    return message;
  }
  
  // Mark messages as read
  static Future<void> markMessagesAsRead(String conversationId) async {
    final conversations = await getConversations();
    final currentUserId = await AuthService.getCurrentUserId();
    
    final index = conversations.indexWhere((c) => c.id == conversationId);
    if (index < 0) {
      return;
    }
    
    // Update messages
    final conversation = conversations[index];
    final messages = conversation.messages.map((message) {
      if (message.senderId != currentUserId && !message.isRead) {
        return ChatMessage(
          id: message.id,
          senderId: message.senderId,
          text: message.text,
          timestamp: message.timestamp,
          isRead: true,
        );
      }
      return message;
    }).toList();
    
    conversations[index] = ChatConversation(
      id: conversation.id,
      participantIds: conversation.participantIds,
      messages: messages,
      lastUpdated: conversation.lastUpdated,
      lastMessagePreview: conversation.lastMessagePreview,
    );
    
    await saveConversations(conversations);
  }
  
  // Add a friend by email
  static Future<Friendship?> addFriendByEmail(String email) async {
    final friendships = await getFriendships();
    final currentUserId = await AuthService.getCurrentUserId();
    
    // For demo purposes, we'll just create a mock user
    // In a real app, this would search the database for the user
    final User? user = await _findUserByEmail(email);
    
    if (user == null) {
      throw Exception('User not found with email: $email');
    }
    
    // Check if friendship already exists
    final existingFriendship = friendships.where((f) => 
      (f.requesterId == currentUserId && f.receiverId == user.id.toString()) ||
      (f.requesterId == user.id.toString() && f.receiverId == currentUserId)
    ).toList();
    
    if (existingFriendship.isNotEmpty) {
      return existingFriendship.first;
    }
    
    // Create new friendship
    final newFriendship = Friendship(
      id: _uuid.v4(),
      requesterId: currentUserId,
      receiverId: user.id.toString(),
      status: FriendshipStatus.pending,
      createdAt: DateTime.now(),
    );
    
    friendships.add(newFriendship);
    await saveFriendships(friendships);
    
    return newFriendship;
  }
  
  // Accept a friend request
  static Future<Friendship?> acceptFriendRequest(String friendshipId) async {
    final friendships = await getFriendships();
    
    final index = friendships.indexWhere((f) => f.id == friendshipId);
    if (index < 0) {
      return null;
    }
    
    // Update friendship
    final friendship = friendships[index];
    
    if (friendship.status != FriendshipStatus.pending) {
      return friendship;
    }
    
    final updatedFriendship = Friendship(
      id: friendship.id,
      requesterId: friendship.requesterId,
      receiverId: friendship.receiverId,
      status: FriendshipStatus.accepted,
      createdAt: friendship.createdAt,
      updatedAt: DateTime.now(),
    );
    
    friendships[index] = updatedFriendship;
    await saveFriendships(friendships);
    
    return updatedFriendship;
  }
  
  // Reject a friend request
  static Future<Friendship?> rejectFriendRequest(String friendshipId) async {
    final friendships = await getFriendships();
    
    final index = friendships.indexWhere((f) => f.id == friendshipId);
    if (index < 0) {
      return null;
    }
    
    // Update friendship
    final friendship = friendships[index];
    
    final updatedFriendship = Friendship(
      id: friendship.id,
      requesterId: friendship.requesterId,
      receiverId: friendship.receiverId,
      status: FriendshipStatus.rejected,
      createdAt: friendship.createdAt,
      updatedAt: DateTime.now(),
    );
    
    friendships[index] = updatedFriendship;
    await saveFriendships(friendships);
    
    return updatedFriendship;
  }
  
  // Remove a friend
  static Future<void> removeFriend(String userId) async {
    final friendships = await getFriendships();
    final currentUserId = await AuthService.getCurrentUserId();
    
    // Remove friendship
    final filteredFriendships = friendships.where((f) => 
      !(f.isAccepted() && f.isUserInvolved(currentUserId) && f.isUserInvolved(userId))
    ).toList();
    
    if (filteredFriendships.length != friendships.length) {
      await saveFriendships(filteredFriendships);
    }
  }
  
  // Get all friends for the current user
  static Future<List<String>> getFriendIds() async {
    final friendships = await getFriendships();
    final currentUserId = await AuthService.getCurrentUserId();
    
    return friendships
        .where((f) => f.isAccepted() && f.isUserInvolved(currentUserId))
        .map((f) => f.getOtherUserId(currentUserId))
        .toList();
  }
  
  // Get pending friend requests received by the current user
  static Future<List<Friendship>> getPendingFriendRequests() async {
    final friendships = await getFriendships();
    final currentUserId = await AuthService.getCurrentUserId();
    
    return friendships
        .where((f) => f.isPending() && f.receiverId == currentUserId)
        .toList();
  }
  
  // Mock method to find a user by email - in a real app, this would query the server
  static Future<User?> _findUserByEmail(String email) async {
    // In a real app, this would be an API call
    // For demo purposes, we'll return a mock user
    if (email.contains('@') && email.contains('.')) {
      return User(
        id: int.parse(_uuid.v4().substring(0, 8), radix: 16),
        email: email,
        fullName: 'Mock User (${email.split('@')[0]})',
      );
    }
    return null;
  }
  
  // Create some mock data for testing
  static Future<void> createMockData() async {
    final currentUserId = await AuthService.getCurrentUserId();
    
    // Create mock friendships
    final mockFriendships = [
      Friendship(
        id: _uuid.v4(),
        requesterId: '123456',
        receiverId: currentUserId,
        status: FriendshipStatus.accepted,
        createdAt: DateTime.now().subtract(Duration(days: 10)),
        updatedAt: DateTime.now().subtract(Duration(days: 9)),
      ),
      Friendship(
        id: _uuid.v4(),
        requesterId: '234567',
        receiverId: currentUserId,
        status: FriendshipStatus.pending,
        createdAt: DateTime.now().subtract(Duration(days: 2)),
      ),
      Friendship(
        id: _uuid.v4(),
        requesterId: currentUserId,
        receiverId: '345678',
        status: FriendshipStatus.accepted,
        createdAt: DateTime.now().subtract(Duration(days: 15)),
        updatedAt: DateTime.now().subtract(Duration(days: 14)),
      ),
    ];
    
    // Create mock conversations
    final mockConversations = [
      ChatConversation(
        id: _uuid.v4(),
        participantIds: [currentUserId, '123456'],
        messages: [
          ChatMessage(
            id: _uuid.v4(),
            senderId: '123456',
            text: 'Hey, how is training going?',
            timestamp: DateTime.now().subtract(Duration(days: 1, hours: 2)),
            isRead: true,
          ),
          ChatMessage(
            id: _uuid.v4(),
            senderId: currentUserId,
            text: 'Great! I\'m preparing for the match this weekend.',
            timestamp: DateTime.now().subtract(Duration(days: 1, hours: 1)),
          ),
          ChatMessage(
            id: _uuid.v4(),
            senderId: '123456',
            text: 'Good luck! Let me know how it goes.',
            timestamp: DateTime.now().subtract(Duration(hours: 23)),
          ),
        ],
        lastUpdated: DateTime.now().subtract(Duration(hours: 23)),
        lastMessagePreview: 'Good luck! Let me know how it goes.',
      ),
      ChatConversation(
        id: _uuid.v4(),
        participantIds: [currentUserId, '345678'],
        messages: [
          ChatMessage(
            id: _uuid.v4(),
            senderId: currentUserId,
            text: 'Are you coming to practice tomorrow?',
            timestamp: DateTime.now().subtract(Duration(days: 2)),
          ),
          ChatMessage(
            id: _uuid.v4(),
            senderId: '345678',
            text: 'Yes, I\'ll be there at 4pm.',
            timestamp: DateTime.now().subtract(Duration(days: 2)).add(Duration(minutes: 5)),
            isRead: true,
          ),
        ],
        lastUpdated: DateTime.now().subtract(Duration(days: 2)).add(Duration(minutes: 5)),
        lastMessagePreview: 'Yes, I\'ll be there at 4pm.',
      ),
    ];
    
    await saveFriendships(mockFriendships);
    await saveConversations(mockConversations);
  }
} 