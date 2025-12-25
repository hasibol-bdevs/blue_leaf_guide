import 'package:flutter/material.dart';

import '../data/goal_service.dart';

class GoalProvider extends ChangeNotifier {
  final GoalService _goalService = GoalService();
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> initializeNewUserData(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _goalService.initializeDefaultGoals(uid);
    } catch (e) {
      debugPrint("Provider Error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}