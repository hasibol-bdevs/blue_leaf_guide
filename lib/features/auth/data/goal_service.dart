import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GoalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initializeDefaultGoals(String uid) async {
    // final user = _auth.currentUser;
    // if (user == null) return;

    final WriteBatch batch = _firestore.batch();

    // Format: "2025-12"
    final String monthKey = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

    // Static data with UNIQUE targets and progress for each task
    final List<Map<String, dynamic>> staticGoals = [
      {
        'templateId': 'K9ibDCZqhqWokqLZqgrD',
        'fullTitle': 'Distribute business card',
        'shortTitle': 'Cards Passed Out',
        'targetNumber': 50,
        'currentProgress': 20,
        'order': 1,
      },
      {
        'templateId': 'GvpSRxjgFPBKsrSxgUZC',
        'fullTitle': 'Total client served',
        'shortTitle': 'Acquired',
        'targetNumber': 10,
        'currentProgress': 5,
        'order': 2,
      },
      {
        'templateId': 'SMcb3badMayTNWO8mm2z',
        'fullTitle': 'Post on social media',
        'shortTitle': 'Posted',
        'targetNumber': 20,
        'currentProgress': 10,
        'order': 3,
      },
      {
        'templateId': 'SVPdZhwLQt7XdH9747PB',
        'fullTitle': 'Attend hair show or class',
        'shortTitle': 'Attended',
        'targetNumber': 1,
        'currentProgress': 0,
        'order': 4,
      },
    ];

    try {
      for (var goal in staticGoals) {
        // Creates a unique document ID for each of the 4 tasks
        final DocumentReference docRef = _firestore
            .collection('users')
            .doc(uid)
            .collection('monthly_goals')
            .doc();

        batch.set(docRef, {
          'templateId': goal['templateId'],
          'fullTitle': goal['fullTitle'],
          'shortTitle': goal['shortTitle'],
          'targetNumber': goal['targetNumber'], // Taken from list
          'currentProgress': goal['currentProgress'], // Taken from list
          'order': goal['order'],
          'month': monthKey,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint("✅ Successfully uploaded 4 unique goal documents.");
    } catch (e) {
      debugPrint("🔴 Upload Error: $e");
      rethrow;
    }
  }
}