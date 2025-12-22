import 'package:cloud_firestore/cloud_firestore.dart';

class PlanningService {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  Future<Map<String, List<bool>>> getPlanningData(String userId) async {
    try {
      final doc = await _firebaseFirestore
          .collection('users')
          .doc(userId)
          .collection('planning')
          .doc('data')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return {
          'month1': List<bool>.from(data['month1'] ?? [false, false, false]),
          'month2': List<bool>.from(data['month2'] ?? [false, false, false]),
          'month3': List<bool>.from(
            data['month3'] ?? [false, false, false, false],
          ),
        };
      } else {
        return {
          'month1': [false, false, false],
          'month2': [false, false, false],
          'month3': [false, false, false, false],
        };
      }
    } catch (e) {
      print('Error loading planning data: $e');
      return {
        'month1': [false, false, false],
        'month2': [false, false, false],
        'month3': [false, false, false, false],
      };
    }
  }

  /// Check if all planning checkboxes are completed
  bool isAllCheckboxesCompleted(
    List<bool> month1,
    List<bool> month2,
    List<bool> month3,
  ) {
    return month1.every((e) => e) &&
        month2.every((e) => e) &&
        month3.every((e) => e);
  }
}
