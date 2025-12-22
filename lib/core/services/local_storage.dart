import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  LocalStorageService._();
  static final LocalStorageService _instance = LocalStorageService._();
  static LocalStorageService get instance => _instance;

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    print(
      '✅ LocalStorageService initialized. Current onboarding: ${_prefs.getBool('onboarding_completed')}',
    );
  }

  Future<void> setOnboardingCompleted() async {
    await _prefs.setBool('onboarding_completed', true);
    print('✅ onboarding_completed set to TRUE in SharedPreferences');
  }

  bool isOnboardingCompleted() {
    return _prefs.getBool('onboarding_completed') ?? false;
  }
}
