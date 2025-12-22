// lib/data/client_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ClientService {
  static final ClientService _instance = ClientService._internal();
  factory ClientService() => _instance;
  ClientService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Get clients collection reference for current user
  CollectionReference get _clientsCollection {
    if (_userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(_userId).collection('clients');
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

  /// Add new client
  Future<Map<String, dynamic>> addClient(
    Map<String, dynamic> clientData,
  ) async {
    try {
      if (_userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      // Create a new map with timestamps to avoid modifying the original
      final dataToSave = Map<String, dynamic>.from(clientData);
      dataToSave['createdAt'] = FieldValue.serverTimestamp();
      dataToSave['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _clientsCollection.add(dataToSave);

      return {
        'success': true,
        'message': 'Client added successfully',
        'clientId': docRef.id,
      };
    } catch (e) {
      print('❌ Error adding client: $e');
      return {'success': false, 'message': 'Failed to add client: $e'};
    }
  }

  /// Update existing client
  Future<Map<String, dynamic>> updateClient(
    String clientId,
    Map<String, dynamic> clientData,
  ) async {
    try {
      if (_userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      // Create a new map with timestamp to avoid modifying the original
      final dataToUpdate = Map<String, dynamic>.from(clientData);
      dataToUpdate['updatedAt'] = FieldValue.serverTimestamp();

      await _clientsCollection.doc(clientId).update(dataToUpdate);

      return {'success': true, 'message': 'Client updated successfully'};
    } catch (e) {
      print('❌ Error updating client: $e');
      return {'success': false, 'message': 'Failed to update client: $e'};
    }
  }

  /// Delete client
  Future<Map<String, dynamic>> deleteClient(String clientId) async {
    try {
      if (_userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      await _clientsCollection.doc(clientId).delete();

      return {'success': true, 'message': 'Client deleted successfully'};
    } catch (e) {
      print('❌ Error deleting client: $e');
      return {'success': false, 'message': 'Failed to delete client: $e'};
    }
  }

  /// Get all clients for current user
  Stream<QuerySnapshot> getClientsStream() {
    // If there's no authenticated user, return an empty stream instead of
    // throwing. This makes callers (StreamBuilder) resilient to unauthenticated
    // states and keeps UI from crashing.
    if (_userId == null) return const Stream.empty();

    return _clientsCollection
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get single client by ID
  Future<DocumentSnapshot?> getClient(String clientId) async {
    try {
      if (_userId == null) return null;
      return await _clientsCollection.doc(clientId).get();
    } catch (e) {
      print('❌ Error getting client: $e');
      return null;
    }
  }
}
