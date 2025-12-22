import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoadmapService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Fetch all roadmaps
  Future<List<Map<String, dynamic>>> fetchRoadmaps() async {
    try {
      final snapshot = await _firestore
          .collection('roadmaps')
          .orderBy('order')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching roadmaps: $e');
      return [];
    }
  }

  // Fetch single roadmap by ID
  Future<Map<String, dynamic>?> fetchRoadmapById(String roadmapId) async {
    try {
      final doc = await _firestore.collection('roadmaps').doc(roadmapId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error fetching roadmap: $e');
      return null;
    }
  }

  // Fetch user progress for all roadmaps
  Future<Map<String, Map<String, dynamic>>> fetchUserProgress() async {
    if (currentUserId == null) return {};

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('roadmapProgress')
          .get();

      final Map<String, Map<String, dynamic>> progressMap = {};
      for (var doc in snapshot.docs) {
        progressMap[doc.id] = doc.data();
      }
      return progressMap;
    } catch (e) {
      print('Error fetching user progress: $e');
      return {};
    }
  }

  // Fetch user progress for specific roadmap
  Future<Map<String, dynamic>?> fetchRoadmapProgress(String roadmapId) async {
    if (currentUserId == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('roadmapProgress')
          .doc(roadmapId)
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Error fetching roadmap progress: $e');
      return null;
    }
  }

  // Save roadmap progress
  Future<bool> saveRoadmapProgress({
    required String roadmapId,
    required List<int> completedChecklist,
    required Map<String, String> reflections,
    required bool completed,
  }) async {
    if (currentUserId == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('roadmapProgress')
          .doc(roadmapId)
          .set({
            'completedChecklist': completedChecklist,
            'reflections': reflections,
            'completed': completed,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error saving roadmap progress: $e');
      return false;
    }
  }

  // Update checklist item
  Future<bool> updateChecklistItem({
    required String roadmapId,
    required int itemIndex,
    required bool isChecked,
    required List<int> currentCompletedList,
  }) async {
    if (currentUserId == null) return false;

    try {
      List<int> updatedList = List.from(currentCompletedList);
      if (isChecked && !updatedList.contains(itemIndex)) {
        updatedList.add(itemIndex);
      } else if (!isChecked && updatedList.contains(itemIndex)) {
        updatedList.remove(itemIndex);
      }

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('roadmapProgress')
          .doc(roadmapId)
          .set({
            'completedChecklist': updatedList,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error updating checklist: $e');
      return false;
    }
  }
}
