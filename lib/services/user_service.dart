// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save user data after sign up
  Future<void> saveUserData(String userId, String email, String name) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'email': email,
        'name': name,
        'createdAt': DateTime.now(),
        'searchKeywords': [
          email.toLowerCase(),
          name.toLowerCase(),
          ...name.toLowerCase().split(' '),
        ],
      });
      print('✅ User data saved to Firestore with name: $name');
    } catch (e) {
      print('❌ Error saving user data: $e');
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('❌ Error getting user data: $e');
      return null;
    }
  }

  // Get user name by ID
  Future<String> getUserName(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['name'] ?? data['email'] ?? 'Unknown User';
      }
      return 'Unknown User';
    } catch (e) {
      print('❌ Error getting user name: $e');
      return 'Unknown User';
    }
  }

  // Get user email by ID
  Future<String> getUserEmail(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['email'] ?? 'Unknown User';
      }
      return 'Unknown User';
    } catch (e) {
      print('❌ Error getting user email: $e');
      return 'Unknown User';
    }
  }

  // Search users by name or email
  Stream<QuerySnapshot> searchUsers(String searchQuery) {
    if (searchQuery.isEmpty) {
      return _firestore.collection('users').snapshots();
    }
    
    String query = searchQuery.toLowerCase();
    return _firestore
        .collection('users')
        .where('searchKeywords', arrayContains: query)
        .snapshots();
  }

  // Update user profile
  Future<void> updateUserProfile(String userId, {String? name, String? email}) async {
    try {
      Map<String, dynamic> updates = {};
      if (name != null) {
        updates['name'] = name;
        // Get current email for search keywords
        final userData = await getUserData(userId);
        String currentEmail = userData?['email'] ?? '';
        updates['searchKeywords'] = [
          currentEmail.toLowerCase(),
          name.toLowerCase(),
          ...name.toLowerCase().split(' '),
        ];
      }
      
      if (email != null) {
        updates['email'] = email;
      }
      
      await _firestore.collection('users').doc(userId).update(updates);
      print('✅ User profile updated');
    } catch (e) {
      print('❌ Error updating user profile: $e');
    }
  }

  // Get all users (for migration)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      print('❌ Error getting all users: $e');
      return [];
    }
  }
}