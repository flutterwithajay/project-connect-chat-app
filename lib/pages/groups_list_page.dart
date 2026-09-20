import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_auth/pages/group_chat_page.dart';
import 'package:flutter_auth/pages/create_group_page.dart';
import 'package:flutter_auth/services/group_service.dart';
import 'package:flutter_auth/theme.dart';

class GroupsListPage extends StatefulWidget {
  const GroupsListPage({super.key});

  @override
  State<GroupsListPage> createState() => _GroupsListPageState();
}

class _GroupsListPageState extends State<GroupsListPage> {
  final GroupService _groupService = GroupService();
  List<DocumentSnapshot> _groups = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Use the Future method that sorts manually
      final groups = await _groupService.getUserGroupsSorted();
      
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading groups: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Update the AppBar in groups_list_page.dart
appBar: AppBar(
  leading: IconButton(
    icon: Icon(Icons.arrow_back, color: Colors.white),
    onPressed: () => Navigator.pop(context),
  ),
  title: Row(
    children: [
      Icon(Icons.groups, size: 24),
      SizedBox(width: 10),
      Text(
        'Group Chats',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    ],
  ),
  backgroundColor: AppTheme.primaryColor,
  elevation: 5,
  actions: [
    IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateGroupPage(),
          ),
        );
      },
      icon: Icon(Icons.group_add),
      tooltip: 'Create New Group',
    ),
  ],
),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 60, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              'Failed to load groups',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadGroups,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group, size: 60, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'No groups yet',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateGroupPage(),
                  ),
                );
              },
              child: const Text('Create Your First Group'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGroups,
      child: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index].data() as Map<String, dynamic>;
          
          return GroupListItem(
            groupName: group['groupName'] ?? 'Group',
            lastMessage: group['lastMessage'] ?? '',
            memberCount: (group['members'] as List).length,
            time: group['lastMessageTime'] != null
                ? (group['lastMessageTime'] as Timestamp).toDate()
                : DateTime.now(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupChatPage(
                    groupId: group['groupId'],
                    groupName: group['groupName'] ?? 'Group',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Group List Item Widget (keep the same)
class GroupListItem extends StatelessWidget {
  final String groupName;
  final String lastMessage;
  final int memberCount;
  final DateTime time;
  final VoidCallback onTap;

  const GroupListItem({
    super.key,
    required this.groupName,
    required this.lastMessage,
    required this.memberCount,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Text(
            groupName.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          groupName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lastMessage.length > 30 
                ? '${lastMessage.substring(0, 30)}...' 
                : lastMessage,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '$memberCount members',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              '${time.day}/${time.month}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}