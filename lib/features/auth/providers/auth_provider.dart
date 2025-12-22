import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/services/notification_service.dart';
import '../data/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isGoogleLoading = false; // NEW: Separate loading state for Google
  String? _errorMessage;
  User? _currentUser;
  Map<String, dynamic>? _userData;

  // Temp storage for signup flow
  String? _pendingEmail;

  bool get isLoading => _isLoading;
  bool get isGoogleLoading => _isGoogleLoading; // NEW: Getter
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  Map<String, dynamic>? get userData => _userData;
  String? get pendingEmail => _pendingEmail;

  AuthProvider() {
    _currentUser = _authService.currentUser;
    if (_currentUser != null) {
      _loadUserData();
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    if (_currentUser != null) {
      _userData = await _authService.getUserData(_currentUser!.uid);

      // Sync notification settings after loading user data
      await NotificationService().syncReminderSettings(_currentUser!.uid);

      notifyListeners();
    }
  }

  // Send OTP for signup
  Future<bool> sendSignUpOTP(String email) async {
    _isLoading = true;
    _errorMessage = null;
    _pendingEmail = email;
    notifyListeners();

    try {
      final result = await _authService.sendOTP(email, type: 'signup');
      _isLoading = false;

      if (!result) {
        _errorMessage = 'Failed to send OTP. Please try again.';
      }

      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Verify OTP
  Future<bool> verifyOTP(String otp) async {
    if (_pendingEmail == null) {
      _errorMessage = 'Email not found. Please start again.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.verifyOTP(_pendingEmail!, otp);
      _isLoading = false;

      if (!result) {
        _errorMessage = 'Invalid or expired OTP. Please try again.';
      }

      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Complete signup with user details
  Future<bool> completeSignUp({
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    if (_pendingEmail == null) {
      _errorMessage = 'Email not found. Please start again.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.createAccount(
        email: _pendingEmail!,
        firstName: firstName,
        lastName: lastName,
        password: password,
      );

      _isLoading = false;

      if (result['success']) {
        _currentUser = result['user'];
        await _loadUserData();
        _pendingEmail = null; // Clear pending email
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Sign in
  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.signIn(
        email: email,
        password: password,
      );

      _isLoading = false;

      if (result['success']) {
        _currentUser = result['user'];
        await _loadUserData();
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Sign in with Google - UPDATED
  Future<bool> signInWithGoogle() async {
    _isGoogleLoading = true; // Changed from _isLoading
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.signInWithGoogle();

      _isGoogleLoading = false; // Changed from _isLoading

      if (result['success']) {
        _currentUser = result['user'];
        print('🟨 Current User $_currentUser');

        await _loadUserData();
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isGoogleLoading = false; // Changed from _isLoading
      _errorMessage = 'An error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Add these methods to your existing AuthProvider class

  // Update user profile
  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    if (_currentUser == null) {
      _errorMessage = 'User not found. Please sign in again.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.updateUserProfile(
        uid: _currentUser!.uid,
        firstName: firstName,
        lastName: lastName,
      );

      _isLoading = false;

      if (result['success']) {
        // Update local user data
        await _loadUserData();
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Update user profile image
  Future<Map<String, dynamic>> updateProfileImage(String imagePath) async {
    if (_currentUser == null) {
      return {
        'success': false,
        'message': 'User not found. Please sign in again.',
      };
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Compress and encode image
      final imageBase64 = await _authService.compressAndEncodeImage(imagePath);

      if (imageBase64 == null) {
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message':
              'Image size exceeds 1MB after compression. Please select a smaller image.',
        };
      }

      final result = await _authService.updateProfileImage(
        uid: _currentUser!.uid,
        imageBase64: imageBase64,
      );

      _isLoading = false;

      if (result['success']) {
        // Update local user data
        await _loadUserData();
        notifyListeners();
        return result;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return result;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An error occurred. Please try again.';
      notifyListeners();
      return {
        'success': false,
        'message': 'An error occurred. Please try again.',
      };
    }
  }

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      _isLoading = false;

      if (result['success']) {
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Send password reset OTP (for forgot password flow)
  Future<bool> sendPasswordResetOTP(String email) async {
    _isLoading = true;
    _errorMessage = null;
    _pendingEmail = email;
    notifyListeners();

    try {
      final result = await _authService.sendPasswordResetOTP(email);
      _isLoading = false;

      if (!result) {
        _errorMessage = 'Failed to send OTP. Please try again.';
      }

      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // In AuthProvider
  Future<bool> deleteAccount() async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.deleteAccount();

    _isLoading = false;

    if (result['success']) {
      _currentUser = null;
      _userData = null;
      _pendingEmail = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  // In AuthProvider
  Future<bool> deleteAllData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Implement your logic to delete all user-related data
      // For example: delete Firestore data
      if (_currentUser != null) {
        final uid = _currentUser!.uid;
        final firestore = FirebaseFirestore.instance;

        // Delete user document
        await firestore.collection('users').doc(uid).delete();

        // Delete OTP verification doc if exists
        await firestore
            .collection('otp_verification')
            .doc(uid)
            .delete()
            .catchError((_) {});

        // Add other collections if needed

        // Optionally, delete Firebase Auth user
        await _currentUser!.delete();
      }

      // Sign out after deletion
      await signOut();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to delete all data. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    // Sign out from Firebase
    await _authService.signOut();

    // Sign out from Google if signed in
    final googleSignIn = GoogleSignIn();
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.signOut();
    }

    _currentUser = null;
    _userData = null;
    _pendingEmail = null;
    notifyListeners();
  }

  // Check if logged in
  Future<bool> checkLoginStatus() async {
    return await _authService.isLoggedIn();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> initializeNotifications() async {
    await NotificationService().initialize();

    // Sync settings if user is logged in
    if (_currentUser != null) {
      await NotificationService().syncReminderSettings(_currentUser!.uid);
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.sendPasswordResetEmail(email);

      if (result['success']) {
        _pendingEmail = email;
        return true;
      } else {
        _errorMessage = result['message'];
        return false;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verify reset code and get email
  Future<String?> verifyPasswordResetCode(String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.verifyPasswordResetCode(code);

      if (result['success']) {
        return result['email'];
      } else {
        _errorMessage = result['message'];
        return null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Confirm password reset
  Future<bool> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );

      if (result['success']) {
        return true;
      } else {
        _errorMessage = result['message'];
        return false;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if email exists
  Future<bool> checkEmailExists(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final exists = await _authService.checkEmailExists(email);
      _isLoading = false;
      notifyListeners();
      return exists;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
