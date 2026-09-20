// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User get currentUser => _auth.currentUser!;

  Future<void> sendMessage(String receiverId, String message) async {
    try {
      List<String> ids = [currentUser.uid, receiverId];
      ids.sort();
      String chatId = ids.join('_');

      // Get sender and receiver info
      Map<String, dynamic> senderInfo = await _getUserInfo(currentUser.uid);
      Map<String, dynamic> receiverInfo = await _getUserInfo(receiverId);

      String senderName = senderInfo['name'] ?? senderInfo['email'] ?? 'Unknown User';
      String receiverName = receiverInfo['name'] ?? receiverInfo['email'] ?? 'Unknown User';
      String senderEmail = senderInfo['email'] ?? 'Unknown Email';
      String receiverEmail = receiverInfo['email'] ?? 'Unknown Email';

      Map<String, dynamic> messageData = {
        'senderId': currentUser.uid,
        'receiverId': receiverId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'readBy': [currentUser.uid],
        'senderEmail': senderEmail,
        'receiverEmail': receiverEmail,
        'senderName': senderName,
        'receiverName': receiverName,
      };

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      await _firestore.collection('chats').doc(chatId).set({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'users': [currentUser.uid, receiverId],
        'userNames': {
          currentUser.uid: senderName,
          receiverId: receiverName,
        },
        'userEmails': {
          currentUser.uid: senderEmail,
          receiverId: receiverEmail,
        },
        'unreadCount': {
          currentUser.uid: 0,
          receiverId: FieldValue.increment(1),
        }
      }, SetOptions(merge: true));

      print('✅ Message sent successfully');

    } catch (e) {
      print('❌ Error sending message: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getMessages(String receiverId) {
    List<String> ids = [currentUser.uid, receiverId];
    ids.sort();
    String chatId = ids.join('_');

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> markMessagesAsRead(String chatPartnerId) async {
    try {
      List<String> ids = [currentUser.uid, chatPartnerId];
      ids.sort();
      String chatId = ids.join('_');

      QuerySnapshot unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('read', isEqualTo: false)
          .get();

      for (var doc in unreadMessages.docs) {
        await doc.reference.update({
          'read': true,
          'readBy': FieldValue.arrayUnion([currentUser.uid]),
        });
      }

      if (unreadMessages.docs.isNotEmpty) {
        await _firestore.collection('chats').doc(chatId).update({
          'unreadCount.$currentUser.uid': 0,
        });
      }
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  Stream<QuerySnapshot> getUserChats() {
    return _firestore
        .collection('chats')
        .where('users', arrayContains: currentUser.uid)
        .snapshots();
  }

  Stream<int> getTotalUnreadCount() {
    return _firestore
        .collection('chats')
        .where('users', arrayContains: currentUser.uid)
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (var doc in snapshot.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            if (data.containsKey('unreadCount') && 
                data['unreadCount'][currentUser.uid] != null) {
              total += (data['unreadCount'][currentUser.uid] as int?) ?? 0;
            }
          }
          return total;
        });
  }

  Future<Map<String, dynamic>> _getUserInfo(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'name': data['name'],
          'email': data['email'],
        };
      }
      return {'name': 'Unknown User', 'email': 'Unknown Email'};
    } catch (e) {
      print('❌ Error getting user info: $e');
      return {'name': 'Unknown User', 'email': 'Unknown Email'};
    }
  }

  Future<Map<String, dynamic>> getChatPartnerInfo(String chatId) async {
    try {
      DocumentSnapshot chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        Map<String, dynamic> data = chatDoc.data() as Map<String, dynamic>;
        List<dynamic> users = data['users'] ?? [];
        Map<String, dynamic> userNames = data['userNames'] ?? {};
        Map<String, dynamic> userEmails = data['userEmails'] ?? {};
        
        String otherUserId = users.firstWhere(
          (id) => id != currentUser.uid,
          orElse: () => '',
        );
        
        if (otherUserId.isNotEmpty) {
          return {
            'userId': otherUserId,
            'userName': userNames[otherUserId] ?? 'Unknown User',
            'userEmail': userEmails[otherUserId] ?? 'Unknown Email',
          };
        }
      }
      return {'userId': '', 'userName': 'Unknown User', 'userEmail': 'Unknown Email'};
    } catch (e) {
      print('❌ Error getting chat partner info: $e');
      return {'userId': '', 'userName': 'Unknown User', 'userEmail': 'Unknown Email'};
    }
  }

  Future<List<DocumentSnapshot>> getUserChatsSorted() async {
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .where('users', arrayContains: currentUser.uid)
          .get();

      final chats = querySnapshot.docs;
      chats.sort((a, b) {
        final timeA = a['lastMessageTime'] as Timestamp?;
        final timeB = b['lastMessageTime'] as Timestamp?;
        
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        
        return timeB.compareTo(timeA);
      });

      return chats;
    } catch (e) {
      print('❌ Error getting sorted chats: $e');
      rethrow;
    }
  }
}