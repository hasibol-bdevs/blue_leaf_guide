import 'dart:convert';
import 'dart:io';

import 'package:blue_leaf_guide/shared/widgets/custom_appbar.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/button.dart';
import '../../../../shared/widgets/text_field.dart' as CustomTextField;
import '../../../auth/providers/auth_provider.dart';
import '../../../home/presentation/widgets/image_source_bottom_sheet.dart';

class ProfileInformationScreen extends StatefulWidget {
  const ProfileInformationScreen({super.key});

  @override
  State<ProfileInformationScreen> createState() =>
      _ProfileInformationScreenState();
}

class _ProfileInformationScreenState extends State<ProfileInformationScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  String? _selectedImagePath;
  bool _isImageLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData;

    if (userData != null) {
      firstNameController.text = userData['firstName'] ?? '';
      lastNameController.text = userData['lastName'] ?? '';
    }
  }

  Future<void> _pickImage() async {
    final source = await showImageSourceBottomSheet(context);
    if (source == null) return;

    final hasPermission = await _requestPermission(source);
    if (!hasPermission) return;

    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImagePath = pickedFile.path;
        _isImageLoading = true;
      });

      // Upload the image
      await _uploadImage(pickedFile.path);
    }
  }

  Future<void> _uploadImage(String imagePath) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final result = await authProvider.updateProfileImage(imagePath);

    setState(() => _isImageLoading = false);

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
      // Reset selected image path on failure
      setState(() => _selectedImagePath = null);
    }
  }

  Future<bool> _requestPermission(ImageSource source) async {
    Permission permission;
    String permissionName;

    if (source == ImageSource.camera) {
      permission = Permission.camera;
      permissionName = 'Camera';
    } else {
      if (Platform.isIOS) {
        permission = Permission.photos;
        permissionName = 'Photos';
      } else {
        final isAndroid13OrHigher = await _isAndroid13OrHigher();
        if (isAndroid13OrHigher) {
          permission = Permission.photos;
          permissionName = 'Photos';
        } else {
          permission = Permission.storage;
          permissionName = 'Storage';
        }
      }
    }

    final status = await permission.status;

    if (status.isGranted) return true;

    if (status.isDenied) {
      final result = await permission.request();
      if (result.isGranted) return true;
      if (result.isPermanentlyDenied) {
        _showPermissionDeniedDialog(permissionName);
        return false;
      }
      return false;
    }

    if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog(permissionName);
      return false;
    }

    return false;
  }

  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    return androidInfo.version.sdkInt >= 33;
  }

  void _showPermissionDeniedDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text(
          '$permissionName permission is required to select images. '
          'Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return; // Errors will show under fields
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.updateProfile(
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      _showError(authProvider.errorMessage ?? 'Failed to update profile');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }

  Widget _buildProfileImage() {
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;
    final firstName = userData?['firstName'] ?? '';
    final photoURL = userData?['photoURL'];

    // Check if we have a newly selected local image
    if (_selectedImagePath != null) {
      return Stack(
        children: [
          Container(
            width: 72.w,
            height: 72.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.lightGrey,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Image.file(
                File(_selectedImagePath!),
                fit: BoxFit.cover,
                width: 72.w,
                height: 72.h,
              ),
            ),
          ),
          if (_isImageLoading)
            Container(
              width: 72.w,
              height: 72.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.5),
              ),
              child: Center(
                child: SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Check if we have a base64-encoded image from Firestore
    if (photoURL != null && photoURL.isNotEmpty) {
      // Check if it's a base64 string (not a URL)
      final isBase64 = !photoURL.startsWith('http');

      return Container(
        width: 72.w,
        height: 72.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.lightGrey,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: isBase64
              ? Image.memory(
                  const Base64Decoder().convert(photoURL),
                  fit: BoxFit.cover,
                  width: 72.w,
                  height: 72.h,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildFallbackAvatar(firstName),
                )
              : Image.network(
                  photoURL,
                  fit: BoxFit.cover,
                  width: 72.w,
                  height: 72.h,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildFallbackAvatar(firstName),
                ),
        ),
      );
    }

    // Fallback: show initial letter
    return Container(
      width: 72.w,
      height: 72.h,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.lightGrey,
      ),
      child: _buildFallbackAvatar(firstName),
    );
  }

  Widget _buildFallbackAvatar(String firstName) {
    return Center(
      child: Text(
        firstName.isNotEmpty ? firstName[0].toUpperCase() : '',
        style: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Personal Information'),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              SizedBox(height: 12.h),

              _buildProfileImage(),

              SizedBox(height: 8.h),

              // Change Image Button
              GestureDetector(
                onTap: _isImageLoading ? null : _pickImage,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  child: Text(
                    'Change Image',
                    style: TextStyle(
                      color: AppColors.textPrimary.withOpacity(0.8),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      letterSpacing: -0.01 * 10,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32.h),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField.TextField(
                      controller: firstNameController,
                      label: '',
                      hint: 'First Name',
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      prefixIconSvg: 'assets/icons/svg/user.svg',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12.h),
                    CustomTextField.TextField(
                      controller: lastNameController,
                      label: '',
                      hint: 'Last Name',
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      prefixIconSvg: 'assets/icons/svg/user.svg',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),

              // Save Button
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return Button(
                    onPressed: _handleSave,
                    text: authProvider.isLoading ? 'Saving...' : 'Save',
                    height: 54.h,
                    borderRadius: BorderRadius.circular(32.r),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    textColor: Colors.white,
                    backgroundColor: AppColors.brand500,
                    isLoading: authProvider.isLoading,
                  );
                },
              ),

              SizedBox(height: 12.h),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.textPrimary.withOpacity(0.5),
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
