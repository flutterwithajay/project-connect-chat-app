// lib/pages/chats_list_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_auth/pages/chat_page.dart';
import 'package:flutter_auth/services/chat_service.dart';
import 'package:flutter_auth/theme.dart';

class ChatsListPage extends StatelessWidget {
  const ChatsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.message, size: 24, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Messages',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 5,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {},
            tooltip: 'Search Messages',
          ),
          StreamBuilder<int>(
            stream: chatService.getTotalUnreadCount(),
            builder: (context, snapshot) {
              int totalUnread = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {},
                    tooltip: 'Notifications',
                  ),
                  if (totalUnread > 0)
                    Positioned(
                      right: 8,
                      top: 8,
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
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatService.getUserChats(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('❌ Error in chats stream: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;
          print('📱 Found ${chats.length} chats');

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat, size: 60, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    'No messages yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Find users to chat with',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              try {
                final chat = chats[index].data() as Map<String, dynamic>;
                final users = chat['users'] as List<dynamic>? ?? [];
                final userNames = chat['userNames'] as Map<String, dynamic>? ?? {};
                final userEmails = chat['userEmails'] as Map<String, dynamic>? ?? {};
                final unreadCount = chat['unreadCount'] as Map<String, dynamic>? ?? {};
                
                String otherUserId = '';
                if (users.isNotEmpty) {
                  otherUserId = users.firstWhere(
                    (userId) => userId != currentUser!.uid,
                    orElse: () => '',
                  );
                }

                if (otherUserId.isEmpty) {
                  return SizedBox.shrink();
                }

                String otherUserName = userNames[otherUserId] ?? 'Unknown User';
                String otherUserEmail = userEmails[otherUserId] ?? 'Unknown Email';
                int unread = unreadCount[currentUser!.uid] ?? 0;

                print('📝 Chat with: $otherUserName, unread: $unread');

                return ChatListItem(
                  userName: otherUserName,
                  userEmail: otherUserEmail,
                  lastMessage: chat['lastMessage'] ?? 'No messages yet',
                  time: chat['lastMessageTime'] != null
                      ? (chat['lastMessageTime'] as Timestamp).toDate()
                      : DateTime.now(),
                  unreadCount: unread,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          receiverId: otherUserId,
                          receiverEmail: otherUserEmail,
                          receiverName: otherUserName,
                        ),
                      ),
                    );
                  },
                );
              } catch (e) {
                print('❌ Error building chat item: $e');
                return SizedBox.shrink();
              }
            },
          );
        },
      ),
    );
  }
}

class ChatListItem extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String lastMessage;
  final DateTime time;
  final int unreadCount;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: unreadCount > 0 ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          userName,
          style: TextStyle(
            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              userEmail,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              lastMessage.length > 35 
                ? '${lastMessage.substring(0, 35)}...' 
                : lastMessage,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(time),
              style: TextStyle(
                fontSize: 12,
                color: unreadCount > 0 ? AppTheme.primaryColor : Colors.grey,
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}