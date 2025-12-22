import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FirestoreDataUploader extends StatefulWidget {
  const FirestoreDataUploader({super.key});

  @override
  State<FirestoreDataUploader> createState() => _FirestoreDataUploaderState();
}

class _FirestoreDataUploaderState extends State<FirestoreDataUploader> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isUploading = false;
  String _uploadStatus = '';

  final List<Map<String, dynamic>> goalTemplatesData = [
    {
      'fullTitle': 'Distribute business card',
      'shortTitle': 'Cards Passed Out',
      'order': 1,
    },
    {
      'fullTitle': 'Total client served',
      'shortTitle': 'Client Serve',
      'order': 2,
    },
    {
      'fullTitle': 'Monthly Money Earned',
      'shortTitle': 'Money Earned',
      'order': 3,
    },
    {
      'fullTitle': 'Post on social media',
      'shortTitle': 'Social Post',
      'order': 4,
    },
    {
      'fullTitle': 'Attend hair show or class',
      'shortTitle': 'Class Attendance',
      'order': 5,
    },
  ];

  Future<void> _uploadGoalTemplates() async {
    setState(() {
      _isUploading = true;
      _uploadStatus = 'Starting upload...';
    });

    try {
      final batch = _firestore.batch();
      int successCount = 0;

      // Check if collection already has data
      final existingDocs = await _firestore.collection('goal_templates').get();

      if (existingDocs.docs.isNotEmpty) {
        setState(() {
          _uploadStatus =
              'Goal templates already exist!\nFound ${existingDocs.docs.length} templates.';
          _isUploading = false;
        });

        // Show dialog asking if user wants to overwrite
        final shouldOverwrite = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Templates Already Exist'),
            content: Text(
              'Found ${existingDocs.docs.length} existing goal templates.\n\nDo you want to delete them and upload fresh data?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete & Upload'),
              ),
            ],
          ),
        );

        if (shouldOverwrite != true) {
          setState(() {
            _uploadStatus = 'Upload cancelled by user.';
            _isUploading = false;
          });
          return;
        }

        // Delete existing documents
        setState(() {
          _uploadStatus = 'Deleting existing templates...';
        });

        for (var doc in existingDocs.docs) {
          batch.delete(doc.reference);
        }
      }

      setState(() {
        _uploadStatus =
            'Uploading ${goalTemplatesData.length} goal templates...';
      });

      // Add new documents
      for (var template in goalTemplatesData) {
        final docRef = _firestore.collection('goal_templates').doc();

        final dataToUpload = {
          ...template,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        batch.set(docRef, dataToUpload);
        successCount++;
      }

      // Commit the batch
      await batch.commit();

      setState(() {
        _uploadStatus =
            '✅ Success!\n\nUploaded $successCount goal templates to Firestore.';
        _isUploading = false;
      });

      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully uploaded $successCount goal templates!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _uploadStatus = '❌ Error uploading data:\n\n$e';
        _isUploading = false;
      });

      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _viewExistingTemplates() async {
    try {
      final snapshot = await _firestore.collection('goal_templates').get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _uploadStatus = 'No goal templates found in Firestore.';
        });
        return;
      }

      final templates = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return '${data['order']}. ${data['fullTitle']} (${data['shortTitle']})';
          })
          .join('\n');

      setState(() {
        _uploadStatus =
            '📋 Found ${snapshot.docs.length} templates:\n\n$templates';
      });
    } catch (e) {
      setState(() {
        _uploadStatus = '❌ Error fetching templates:\n\n$e';
      });
    }
  }

  Future<void> _deleteAllTemplates() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Templates?'),
        content: const Text(
          'This will permanently delete all goal templates from Firestore.\n\nThis action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isUploading = true;
      _uploadStatus = 'Deleting all templates...';
    });

    try {
      final snapshot = await _firestore.collection('goal_templates').get();
      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      setState(() {
        _uploadStatus =
            '✅ Deleted ${snapshot.docs.length} templates successfully.';
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All templates deleted successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _uploadStatus = '❌ Error deleting templates:\n\n$e';
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Data Uploader'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        SizedBox(width: 8.w),
                        Text(
                          'Goal Templates Uploader',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'This will upload ${goalTemplatesData.length} predefined goal templates to Firestore.',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Upload Button
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadGoalTemplates,
              icon: _isUploading
                  ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(
                _isUploading ? 'Uploading...' : 'Upload Goal Templates',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),

            SizedBox(height: 12.h),

            // View Existing Button
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _viewExistingTemplates,
              icon: const Icon(Icons.list),
              label: Text(
                'View Existing Templates',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),

            SizedBox(height: 12.h),

            // Delete All Button
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _deleteAllTemplates,
              icon: const Icon(Icons.delete_forever),
              label: Text(
                'Delete All Templates',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Status Display
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _uploadStatus.isEmpty
                        ? 'Ready to upload data.\n\nClick "Upload Goal Templates" to start.'
                        : _uploadStatus,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontFamily: 'monospace',
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Templates Preview
            Card(
              color: Colors.grey.shade50,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Templates to Upload:',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    ...goalTemplatesData.map(
                      (template) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        child: Row(
                          children: [
                            Container(
                              width: 24.w,
                              height: 24.h,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${template['order']}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    template['fullTitle'],
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Short: ${template['shortTitle']}',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
