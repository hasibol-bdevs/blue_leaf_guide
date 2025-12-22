import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_otp/email_otp.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // final GoogleSignIn _googleSignIn = GoogleSignIn();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '1022593340174-b99mnq2r13vukratcoafrla2r0kbjhk7.apps.googleusercontent.com'
        : null,
  );

  AuthService() {
    // Initialize EmailOTP globally
    EmailOTP.config(
      appEmail: 'noreply@blueleafguide.com',
      appName: 'Blue Leaf Guide',
      otpType: OTPType.numeric,
      otpLength: 4, // 4-digit OTP
      emailTheme: EmailTheme.v6,
      expiry: 5 * 60 * 1000, // 5 minutes
    );

    EmailOTP.setSMTP(
      host: 'smtp.gmail.com',
      emailPort: EmailPort.port587, // TLS
      secureType: SecureType.tls,
      username: 'shakibshovon.10@gmail.com', // Your Gmail address
      password: 'slae hwga xxdz vvro', // Your 16-char App Password
    );
  }

  /// Send OTP to email and store in Firestore
  Future<bool> sendOTP(String email, {String type = 'signup'}) async {
    try {
      // Send OTP via email
      final result = await EmailOTP.sendOTP(email: email);

      if (result) {
        // Get the generated OTP
        final generatedOTP = EmailOTP.getOTP();

        final docId = email.replaceAll('.', ',');
        try {
          await _firestore.collection('otp_verification').doc(docId).set({
            'otp': generatedOTP,
            'type': type,
            'createdAt': FieldValue.serverTimestamp(),
            'expiresAt': DateTime.now().add(const Duration(minutes: 5)),
          });
          print('✅ Firestore document created: $docId');
        } catch (e) {
          print('❌ Firestore error: $e');
        }

        print('✅ OTP sent successfully to $email: $generatedOTP');
        return true;
      } else {
        print('❌ Failed to send OTP to $email');
        return false;
      }
    } catch (e) {
      print('❌ Error sending OTP: $e');
      return false;
    }
  }

  Future<bool> verifyOTP(String email, String otp) async {
    try {
      final docId = email.replaceAll('.', ','); // same as when saving
      final doc = await _firestore
          .collection('otp_verification')
          .doc(docId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      final storedOTP = data['otp'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();

      if (DateTime.now().isAfter(expiresAt)) {
        await _firestore.collection('otp_verification').doc(docId).delete();
        return false;
      }

      if (storedOTP == otp) {
        await _firestore.collection('otp_verification').doc(docId).delete();
        return true;
      }

      return false;
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }

  // Create user account with email and password
  Future<Map<String, dynamic>> createAccount({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save additional user info in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Save login state
      await _saveLoginState(userCredential.user!.uid);

      return {
        'success': true,
        'message': 'Account created successfully',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getAuthErrorMessage(e.code)};
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred. Please try again.',
      };
    }
  }

  // Sign in with email and password
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save login state
      await _saveLoginState(userCredential.user!.uid);

      return {
        'success': true,
        'message': 'Signed in successfully',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getAuthErrorMessage(e.code)};
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred. Please try again.',
      };
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();

    // Clear only auth-related preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('isLoggedIn');

    // Sign out from Google if signed in
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('userId') && _auth.currentUser != null;
  }

  // Save login state
  Future<void> _saveLoginState(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setBool('isLoggedIn', true);
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Get auth error message
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled
        return {'success': false, 'message': 'Sign in cancelled'};
      }

      // Get auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;
      final uid = user.uid;

      // Split name
      final nameParts = user.displayName?.split(' ') ?? ['', ''];

      // Check if user exists to decide on photoURL logic
      final userDoc = await _firestore.collection('users').doc(uid).get();
      String? currentPhotoURL;
      if (userDoc.exists) {
        currentPhotoURL = userDoc.data()?['photoURL'];
      }

      // Determine if the current image is a custom uploaded image (Base64)
      // We assume URLs start with 'http'. If it's not empty and doesn't start with http, it's likely Base64.
      bool hasCustomImage =
          currentPhotoURL != null &&
          currentPhotoURL.isNotEmpty &&
          !currentPhotoURL.startsWith('http');

      final Map<String, dynamic> userData = {
        'firstName': nameParts.isNotEmpty ? nameParts[0] : '',
        'lastName': nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
        'email': user.email ?? '',
        'provider': 'google',
        'googlePhotoURL': user.photoURL ?? '', // Store Google photo as fallback
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only update photoURL if the user DOES NOT have a custom image
      // This ensures we don't overwrite their uploaded profile picture with the Google one on every login
      if (!hasCustomImage) {
        userData['photoURL'] = user.photoURL ?? '';
      }

      if (!userDoc.exists) {
        userData['createdAt'] = FieldValue.serverTimestamp();
      }

      // Save/update Firestore user document
      await _firestore
          .collection('users')
          .doc(uid)
          .set(userData, SetOptions(merge: true));

      // Save login state
      await _saveLoginState(uid);

      return {
        'success': true,
        'message': 'Signed in with Google successfully',
        'user': user,
        'isNewUser':
            false, // optional: can detect by checking doc existence if needed
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getAuthErrorMessage(e.code)};
    } catch (e) {
      print('Google Sign-In Error: $e');
      return {
        'success': false,
        'message': 'An error occurred during Google sign-in. Please try again.',
      };
    }
  }

  // Add these methods to your existing AuthService class

  // Update user profile information
  Future<Map<String, dynamic>> updateUserProfile({
    required String uid,
    required String firstName,
    required String lastName,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'firstName': firstName,
        'lastName': lastName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Profile updated successfully'};
    } catch (e) {
      print('Error updating profile: $e');
      return {
        'success': false,
        'message': 'Failed to update profile. Please try again.',
      };
    }
  }

  /// Compress and convert image to base64
  Future<String?> compressAndEncodeImage(String imagePath) async {
    try {
      final dir = Directory.systemTemp;
      final targetPath =
          '${dir.absolute.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        targetPath,
        quality: 70,
        minWidth: 600,
        minHeight: 600,
      );

      if (result == null) return null;

      // Check compressed size
      final fileSize = await result.length();
      final fileSizeInMB = fileSize / (1024 * 1024);

      print('🟨 Compressed image size: ${fileSizeInMB.toStringAsFixed(2)} MB');

      if (fileSizeInMB > 1) {
        print('❌ Image size exceeds 1MB after compression');
        return null;
      }

      // Convert to base64
      final bytes = await result.readAsBytes();
      final base64String = base64Encode(bytes);

      return base64String;
    } catch (e) {
      print('❌ Error compressing image: $e');
      return null;
    }
  }

  /// Update user profile image
  Future<Map<String, dynamic>> updateProfileImage({
    required String uid,
    required String imageBase64,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'photoURL': imageBase64,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Profile image updated successfully'};
    } catch (e) {
      print('Error updating profile image: $e');
      return {
        'success': false,
        'message': 'Failed to update profile image. Please try again.',
      };
    }
  }

  // Verify current password
  Future<bool> verifyCurrentPassword(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      print('Password verification failed: ${e.code}');
      return false;
    } catch (e) {
      print('Error verifying password: $e');
      return false;
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return {
          'success': false,
          'message': 'User not found. Please sign in again.',
        };
      }

      // First verify current password
      final isValid = await verifyCurrentPassword(currentPassword);
      if (!isValid) {
        return {'success': false, 'message': 'Current password is incorrect.'};
      }

      // Update password
      await user.updatePassword(newPassword);

      return {'success': true, 'message': 'Password changed successfully'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getAuthErrorMessage(e.code)};
    } catch (e) {
      print('Error changing password: $e');
      return {
        'success': false,
        'message': 'Failed to change password. Please try again.',
      };
    }
  }

  // Send password reset OTP
  Future<bool> sendPasswordResetOTP(String email) async {
    return await sendOTP(email, type: 'password_reset');
  }

  // Reset password with OTP verification
  Future<Map<String, dynamic>> resetPasswordWithOTP({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      // Verify OTP first
      final isValidOTP = await verifyOTP(email, otp);
      if (!isValidOTP) {
        return {'success': false, 'message': 'Invalid or expired OTP'};
      }

      // Send password reset email (Firebase will handle the reset)
      await _auth.sendPasswordResetEmail(email: email);

      return {
        'success': true,
        'message': 'Password reset email sent. Please check your inbox.',
      };
    } catch (e) {
      print('Error resetting password: $e');
      return {
        'success': false,
        'message': 'Failed to reset password. Please try again.',
      };
    }
  }

  // In AuthService
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No user signed in.'};
      }

      final uid = user.uid;

      // Delete user data from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Delete user from Firebase Auth
      await user.delete();

      // Clear local login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Sign out from Google if signed in
      if (await GoogleSignIn().isSignedIn()) {
        await GoogleSignIn().signOut();
      }

      return {'success': true, 'message': 'Account deleted successfully'};
    } on FirebaseAuthException catch (e) {
      // If recent login required
      if (e.code == 'requires-recent-login') {
        return {'success': false, 'message': 'Please re-login and try again.'};
      }
      return {
        'success': false,
        'message': e.message ?? 'Failed to delete account',
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete account'};
    }
  }

  Future<void> syncNotificationSettings(String uid) async {
    await NotificationService().syncReminderSettings(uid);
  }

  // Check if user is signed in with Google
  Future<bool> isSignedInWithGoogle() async {
    return await _googleSignIn.isSignedIn();
  }

  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://blue-leaf-guide.firebaseapp.com/__/auth/action',
        handleCodeInApp: true, // This tells Firebase to open the app
        androidPackageName: 'com.example.blue_leaf_guide',
        androidInstallApp: true,
        androidMinimumVersion: '21',
        iOSBundleId: 'com.yourcompany.blueleafguide',
      );

      await _auth.sendPasswordResetEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );

      return {
        'success': true,
        'message': 'Password reset email sent successfully',
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getAuthErrorMessage(e.code)};
    } catch (e) {
      print('Error sending password reset email: $e');
      return {
        'success': false,
        'message': 'Failed to send password reset email. Please try again.',
      };
    }
  }

  // Verify password reset code
  Future<Map<String, dynamic>> verifyPasswordResetCode(String code) async {
    try {
      final email = await _auth.verifyPasswordResetCode(code);
      return {
        'success': true,
        'email': email,
        'message': 'Code verified successfully',
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-action-code':
          message = 'Invalid or expired reset code. Please request a new one.';
          break;
        case 'expired-action-code':
          message = 'Reset code has expired. Please request a new one.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        default:
          message = _getAuthErrorMessage(e.code);
      }
      return {'success': false, 'message': message};
    } catch (e) {
      print('Error verifying reset code: $e');
      return {'success': false, 'message': 'Invalid or expired reset code.'};
    }
  }

  // Confirm password reset with new password
  Future<Map<String, dynamic>> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    try {
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);

      return {'success': true, 'message': 'Password reset successfully'};
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'Password is too weak. Please use a stronger password.';
          break;
        case 'invalid-action-code':
          message = 'Invalid or expired reset code. Please request a new one.';
          break;
        case 'expired-action-code':
          message = 'Reset code has expired. Please request a new one.';
          break;
        default:
          message = _getAuthErrorMessage(e.code);
      }
      return {'success': false, 'message': message};
    } catch (e) {
      print('Error confirming password reset: $e');
      return {
        'success': false,
        'message': 'Failed to reset password. Please try again.',
      };
    }
  }

  // Check if email already exists
  Future<bool> checkEmailExists(String email) async {
    try {
      final result = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      return result.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email existence: $e');
      return false;
    }
  }
}
