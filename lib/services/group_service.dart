// lib/services/group_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User get currentUser => _auth.currentUser!;

  // Create a new group
  Future<void> createGroup(String groupName, List<String> memberIds) async {
    try {
      // Add current user to members if not already included
      if (!memberIds.contains(currentUser.uid)) {
        memberIds.add(currentUser.uid);
      }

      // Get user emails for member names
      Map<String, String> memberNames = {};
      for (String memberId in memberIds) {
        String email = await _getUserEmail(memberId);
        memberNames[memberId] = email;
      }

      // Create group document
      String groupId = _firestore.collection('groups').doc().id;
      
      await _firestore.collection('groups').doc(groupId).set({
        'groupId': groupId,
        'groupName': groupName,
        'createdBy': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'members': memberIds,
        'memberNames': memberNames,
        'lastMessage': 'Group created by ${await _getUserEmail(currentUser.uid)}',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdByEmail': await _getUserEmail(currentUser.uid),
      });

      print('✅ Group created successfully: $groupId');
    } catch (e) {
      print('❌ Error creating group: $e');
      rethrow;
    }
  }

  // Send message to group
  Future<void> sendGroupMessage(String groupId, String message) async {
    try {
      Map<String, dynamic> messageData = {
        'senderId': currentUser.uid,
        'senderEmail': await _getUserEmail(currentUser.uid),
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'groupId': groupId,
      };

      // Add message to subcollection
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .add(messageData);

      // Update group's last message
      await _firestore.collection('groups').doc(groupId).update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      print('✅ Group message sent to $groupId');
    } catch (e) {
      print('❌ Error sending group message: $e');
      rethrow;
    }
  }

  // Get group messages
  Stream<QuerySnapshot> getGroupMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Get all groups where current user is a member
  Stream<QuerySnapshot> getUserGroups() {
    return _firestore
        .collection('groups')
        .where('members', arrayContains: currentUser.uid)
        .snapshots();
  }

  // Get groups with client-side sorting
  Future<List<DocumentSnapshot>> getUserGroupsSorted() async {
    try {
      final querySnapshot = await _firestore
          .collection('groups')
          .where('members', arrayContains: currentUser.uid)
          .get();

      final groups = querySnapshot.docs;
      groups.sort((a, b) {
        final timeA = a['lastMessageTime'] as Timestamp?;
        final timeB = b['lastMessageTime'] as Timestamp?;
        
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        
        return timeB.compareTo(timeA);
      });

      return groups;
    } catch (e) {
      print('❌ Error getting sorted groups: $e');
      rethrow;
    }
  }

  // Helper method to get user email
  Future<String> _getUserEmail(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return data['email']?.toString() ?? 'Unknown User';
      }
      return 'Unknown User';
    } catch (e) {
      print('❌ Error getting user email: $e');
      return 'Unknown User';
    }
  }

  // Get group info by ID
  Future<Map<String, dynamic>?> getGroupInfo(String groupId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('groups').doc(groupId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('❌ Error getting group info: $e');
      return null;
    }
  }

  // Add member to group
  Future<void> addMemberToGroup(String groupId, String newMemberId) async {
    try {
      final newMemberEmail = await _getUserEmail(newMemberId);
      
      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([newMemberId]),
        'memberNames.$newMemberId': newMemberEmail,
      });
      
      print('✅ Added member $newMemberId to group $groupId');
    } catch (e) {
      print('❌ Error adding member to group: $e');
      rethrow;
    }
  }
}