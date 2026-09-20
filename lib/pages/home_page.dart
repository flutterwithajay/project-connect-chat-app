// lib/pages/home_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_auth/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_auth/pages/chats_list_page.dart';
import 'package:flutter_auth/pages/chat_page.dart';
import 'package:flutter_auth/pages/groups_list_page.dart';
import 'package:flutter_auth/theme.dart';
import 'package:flutter_auth/services/chat_service.dart';
import 'package:flutter_auth/services/notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;
  final UserService _userService = UserService();
  final ChatService _chatService = ChatService();
  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  String? currentUserName;
  final Set<String> _shownNotifications = {};

  @override
  void initState() {
    super.initState();
    loadAllUsers();
    _loadCurrentUserName();
    _listenForNewMessages();
  }

  Future<void> _loadCurrentUserName() async {
    if (user != null) {
      final userData = await _userService.getUserData(user!.uid);
      setState(() {
        currentUserName = userData?['name'] ?? user?.email?.split('@')[0] ?? 'User';
      });
    }
  }

  void _listenForNewMessages() {
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('chats')
        .where('users', arrayContains: user!.uid)
        .snapshots()
        .listen((snapshot) {
          for (var doc in snapshot.docChanges) {
            if (doc.type == DocumentChangeType.modified) {
              Map<String, dynamic> data = doc.doc.data() as Map<String, dynamic>;
              Map<String, dynamic> unreadCount = data['unreadCount'] ?? {};
              
              if (unreadCount[user!.uid] != null && unreadCount[user!.uid] > 0) {
                _showNewMessageNotification(doc.doc.id, data);
              }
            }
          }
        });
  }

  void _showNewMessageNotification(String chatId, Map<String, dynamic> chatData) async {
    final partnerInfo = await _chatService.getChatPartnerInfo(chatId);
    
    String notificationKey = '${chatId}_${DateTime.now().millisecondsSinceEpoch}';
    
    if (_shownNotifications.contains(notificationKey)) return;
    
    _shownNotifications.add(notificationKey);
    
    Future.delayed(const Duration(seconds: 10), () {
      _shownNotifications.remove(notificationKey);
    });

    if (mounted) {
      NotificationService.showSnackBarNotification(
        context: context,
        senderName: partnerInfo['userName'],
        message: chatData['lastMessage'] ?? 'New message',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                receiverId: partnerInfo['userId'],
                receiverEmail: partnerInfo['userEmail'] ?? partnerInfo['userName'],
                receiverName: partnerInfo['userName'],
              ),
            ),
          );
        },
      );
    }
  }

  Future<void> loadAllUsers() async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      List<Map<String, dynamic>> users = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        users.add({
          'id': doc.id,
          ...userData,
          'displayName': userData['name'] ?? userData['email']?.split('@')[0] ?? 'Unknown User',
        });
      }

      setState(() {
        allUsers = users;
        filteredUsers = users;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void searchUsers(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredUsers = allUsers;
      });
      return;
    }

    String searchText = query.toLowerCase();
    List<Map<String, dynamic>> results = allUsers.where((user) {
      String email = user['email']?.toString().toLowerCase() ?? '';
      String name = user['name']?.toString().toLowerCase() ?? '';
      return email.contains(searchText) || name.contains(searchText);
    }).toList();

    setState(() {
      filteredUsers = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.connect_without_contact,
              color: Colors.white,
              size: 28,
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ProjectConnect",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  "Welcome, ${currentUserName ?? user?.email?.split('@')[0] ?? 'User'}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 10,
        shadowColor: AppTheme.primaryColor.withOpacity(0.3),
        centerTitle: false,
        actions: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.2),
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GroupsListPage(),
                    ),
                  );
                },
                icon: Icon(Icons.groups, color: Colors.white),
                tooltip: 'Group Chats',
              ),
            ),
          ),
          
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            child: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatsListPage(),
                        ),
                      );
                    },
                    icon: Icon(Icons.message, color: Colors.white),
                    tooltip: 'Private Messages',
                  ),
                ),
                StreamBuilder<int>(
                  stream: _chatService.getTotalUnreadCount(),
                  builder: (context, snapshot) {
                    int totalUnread = snapshot.data ?? 0;
                    if (totalUnread == 0) return SizedBox.shrink();
                    
                    return Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          totalUnread > 9 ? '9+' : totalUnread.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.2),
              child: IconButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                icon: Icon(Icons.logout, color: Colors.white),
                tooltip: 'Logout',
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          searchUsers('');
                        },
                      )
                    : null,
              ),
              onChanged: searchUsers,
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 60, color: Colors.grey),
                            const SizedBox(height: 20),
                            Text(
                              searchController.text.isEmpty
                                  ? 'No users found'
                                  : 'No users found for "${searchController.text}"',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          Map<String, dynamic> userData = filteredUsers[index];
                          return UserCard(userData: userData);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class UserCard extends StatelessWidget {
  final Map<String, dynamic> userData;

  const UserCard({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    String name = userData['name'] ?? '';
    String email = userData['email'] ?? 'No email';
    String displayName = name.isNotEmpty ? name : email.split('@')[0];
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue.shade100,
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          displayName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            if (userData['createdAt'] != null)
              Text(
                'Joined: ${_formatDate(userData['createdAt'])}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            icon: Icon(Icons.message, color: Colors.blue.shade700),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    receiverId: userData['id'],
                    receiverEmail: email,
                    receiverName: displayName,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    if (date is Timestamp) {
      return '${date.toDate().day}/${date.toDate().month}/${date.toDate().year}';
    }
    return date.toString().split(' ')[0];
  }
}