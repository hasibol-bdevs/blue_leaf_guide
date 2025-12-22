import 'package:flutter/foundation.dart';

class SubtitleProvider extends ChangeNotifier {
  String _subtitle = "";

  String get subtitle => _subtitle;

  void setSubtitle(String value) {
    _subtitle = value;
    notifyListeners();
  }
}
