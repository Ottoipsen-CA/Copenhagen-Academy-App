import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/chat.dart';
import '../../models/friendship.dart';
import '../../models/user.dart';
import '../../services/chat_service.dart';
import 'chat_detail_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ChatConversation> _conversations = [];
  List<Friendship> _pendingRequests = [];
  bool _isLoading = true;
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First create some mock data for testing
      await ChatService.createMockData();
      
      final conversations = await ChatService.getConversations();
      final pendingRequests = await ChatService.getPendingFriendRequests();
      
      setState(() {
        _conversations = conversations;
        _pendingRequests = pendingRequests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data: $e';
      });
    }
  }

  Future<void> _addFriend() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final friendship = await ChatService.addFriendByEmail(email);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request sent to $email'),
          backgroundColor: Colors.green,
        ),
      );
      
      _emailController.clear();
      await _loadData(); // Refresh the data
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to add friend: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage ?? 'An error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _acceptFriendRequest(Friendship friendship) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ChatService.acceptFriendRequest(friendship.id);
      await _loadData(); // Refresh the data
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to accept friend request: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage ?? 'An error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectFriendRequest(Friendship friendship) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ChatService.rejectFriendRequest(friendship.id);
      await _loadData(); // Refresh the data
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to reject friend request: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage ?? 'An error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openChatDetail(ChatConversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(conversationId: conversation.id),
      ),
    ).then((_) => _loadData()); // Refresh when returning
  }

  Widget _buildConversationList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_conversations.isEmpty) {
      return const Center(
        child: Text(
          'No conversations yet.\nAdd friends to start chatting!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        final lastMessage = conversation.messages.isNotEmpty
            ? conversation.messages.last
            : null;
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          title: Text('Friend ${index + 1}'), // In a real app, fetch the user's name
          subtitle: Text(
            conversation.lastMessagePreview ?? 'Start a conversation',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: lastMessage != null
              ? Text(
                  DateFormat.jm().format(lastMessage.timestamp),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                )
              : null,
          onTap: () => _openChatDetail(conversation),
        );
      },
    );
  }

  Widget _buildFriendRequestsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Add Friend Form
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Friend\'s Email',
                    hintText: 'Enter email address',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email address';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addFriend,
                  child: const Text('Add Friend'),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const Divider(),
        
        // Pending Friend Requests
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Friend Requests (${_pendingRequests.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        Expanded(
          child: _pendingRequests.isEmpty
              ? const Center(
                  child: Text(
                    'No pending friend requests',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _pendingRequests.length,
                  itemBuilder: (context, index) {
                    final request = _pendingRequests[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_add),
                      ),
                      title: const Text('New Friend Request'),
                      subtitle: Text('From user ${request.requesterId}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _acceptFriendRequest(request),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _rejectFriendRequest(request),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Conversations'),
            Tab(text: 'Friends'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConversationList(),
          _buildFriendRequestsList(),
        ],
      ),
    );
  }
} 