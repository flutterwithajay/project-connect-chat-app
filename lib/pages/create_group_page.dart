import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_auth/services/group_service.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final GroupService _groupService = GroupService();
  final TextEditingController _groupNameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final currentUser = FirebaseAuth.instance.currentUser;

  List<Map<String, dynamic>> allUsers = [];
  List<String> selectedUserIds = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadAllUsers();
  }

  Future<void> loadAllUsers() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('email', isNotEqualTo: currentUser!.email) // Exclude current user
          .get();

      List<Map<String, dynamic>> users = [];
      for (var doc in querySnapshot.docs) {
        users.add({
          'id': doc.id,
          'email': doc['email'],
        });
      }

      setState(() {
        allUsers = users;
      });
    } catch (e) {
      print('Error loading users: $e');
    }
  }

  Future<void> createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    if (selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await _groupService.createGroup(
        _groupNameController.text.trim(),
        selectedUserIds,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group created successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Group'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Name Input
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
            ),
            const SizedBox(height: 20),

            // Selected Members
            Text(
              'Selected Members: ${selectedUserIds.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Members List
            Expanded(
              child: ListView.builder(
                itemCount: allUsers.length,
                itemBuilder: (context, index) {
                  final user = allUsers[index];
                  final isSelected = selectedUserIds.contains(user['id']);

                  return CheckboxListTile(
                    title: Text(user['email']),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedUserIds.add(user['id']);
                        } else {
                          selectedUserIds.remove(user['id']);
                        }
                      });
                    },
                  );
                },
              ),
            ),

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create Group'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}