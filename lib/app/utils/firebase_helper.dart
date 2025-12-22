import 'package:firebase_core/firebase_core.dart';

/// Initializes Firebase and logs the result
Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully!');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
  }
}
