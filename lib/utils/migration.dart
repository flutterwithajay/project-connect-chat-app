// lib/utils/migration.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Migration {
  static Future<void> addNamesToExistingUsers() async {
    try {
      print('🔄 Starting migration: Adding names to existing users...');
      
      // Get all users from Firestore
      QuerySnapshot users = await FirebaseFirestore.instance.collection('users').get();
      int updatedCount = 0;
      
      // Loop through each user
      for (var doc in users.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // If user doesn't have a name, create one from email
        if (!data.containsKey('name') || data['name'] == null || data['name'].isEmpty) {
          String email = data['email'] ?? '';
          String name = email.split('@')[0]; // Get part before @
          
          // Make name look nice (e.g., "john.doe" -> "John Doe")
          name = name.split(RegExp(r'[._-]')).map((part) {
            if (part.isEmpty) return '';
            return part[0].toUpperCase() + part.substring(1).toLowerCase();
          }).join(' ');
          
          // Update the user document with name
          await doc.reference.update({
            'name': name,
          });
          
          updatedCount++;
          print('✅ Added name "$name" for user ${doc.id}');
        }
      }
      
      print('✅ Migration completed! Updated $updatedCount users.');
    } catch (e) {
      print('❌ Migration error: $e');
    }
  }
}