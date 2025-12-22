import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentTab = 0;

  int get currentTab => _currentTab;

  void setTab(int tabIndex) {
    if (_currentTab != tabIndex) {
      _currentTab = tabIndex;
      notifyListeners();
    }
  }

  void resetTab() {
    _currentTab = 0;
    notifyListeners();
  }
}
