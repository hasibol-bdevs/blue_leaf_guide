// lib/features/clients/screens/add_client_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/custom_date_picker_dialog.dart';
import '../../../../shared/widgets/button.dart';
import '../../../../shared/widgets/custom_appbar.dart';
import '../../../../shared/widgets/custom_popup_menu.dart';
import '../../../../shared/widgets/text_field.dart' as custom;
import '../../data/client_service.dart';
import '../widgets/image_source_bottom_sheet.dart';

class AddClientScreen extends StatefulWidget {
  final Map<String, dynamic>? extra;

  const AddClientScreen({super.key, this.extra});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController joinDateController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();
  final TextEditingController tiktokController = TextEditingController();
  final TextEditingController linkedinController = TextEditingController();
  final TextEditingController twitterController = TextEditingController();

  String? clientType = 'Client type';
  final List<String> clientTypes = ['Personal Client', 'School Client'];

  String? _selectedImagePath;
  String? _existingImageBase64;
  bool _isLoading = false;
  bool _isEditMode = false;
  String? _clientId;

  @override
  void initState() {
    super.initState();
    _loadClientData();
  }

  void _loadClientData() {
    if (widget.extra != null) {
      _isEditMode = true;
      _clientId = widget.extra!['clientId'];
      final clientData = widget.extra!['clientData'] as Map<String, dynamic>;

      firstNameController.text = clientData['firstName'] ?? '';
      lastNameController.text = clientData['lastName'] ?? '';
      emailController.text = clientData['email'] ?? '';
      phoneController.text = clientData['phone'] ?? '';
      joinDateController.text = clientData['joinDate'] ?? '';
      instagramController.text = clientData['instagram'] ?? '';
      tiktokController.text = clientData['tiktok'] ?? '';
      linkedinController.text = clientData['linkedin'] ?? '';
      twitterController.text = clientData['twitter'] ?? '';
      clientType = clientData['clientType'] ?? 'Regular';
      _existingImageBase64 = clientData['profileImage'];
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    joinDateController.dispose();
    instagramController.dispose();
    tiktokController.dispose();
    linkedinController.dispose();
    twitterController.dispose();
    super.dispose();
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
      setState(() => _selectedImagePath = pickedFile.path);
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return CustomDatePickerDialog(
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now().add(
            const Duration(days: 3650),
          ), // future 10 years
          disablePastDates: true, // ENABLE: only current & future dates
        );
      },
    );

    if (picked != null) {
      final formattedDate = DateFormat('MMM dd, yyyy').format(picked);
      setState(() {
        joinDateController.text = formattedDate;
      });
    }
  }

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _validatePhone(String phone) {
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
    return phoneRegex.hasMatch(phone) && phone.length >= 10;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.timelinePrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill in all required fields', isError: true);
      return;
    }

    if (!_validateEmail(emailController.text)) {
      _showSnackBar('Please enter a valid email address', isError: true);
      return;
    }

    if (!_validatePhone(phoneController.text)) {
      _showSnackBar('Please enter a valid phone number', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageBase64;

      if (_selectedImagePath != null) {
        imageBase64 = await ClientService().compressAndEncodeImage(
          _selectedImagePath!,
        );
        if (imageBase64 == null) {
          _showSnackBar(
            'Image size exceeds 1MB after compression. Please select a smaller image.',
            isError: true,
          );
          setState(() => _isLoading = false);
          return;
        }
      } else if (_isEditMode && _existingImageBase64 != null) {
        imageBase64 = _existingImageBase64;
      }

      final clientData = {
        'profileImage': imageBase64 ?? '',
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'clientType': clientType,
        'joinDate': joinDateController.text.trim(),
        'instagram': instagramController.text.trim(),
        'tiktok': tiktokController.text.trim(),
        'linkedin': linkedinController.text.trim(),
        'twitter': twitterController.text.trim(),
      };

      Map<String, dynamic> result;

      if (_isEditMode && _clientId != null) {
        result = await ClientService().updateClient(_clientId!, clientData);
      } else {
        result = await ClientService().addClient(clientData);
      }

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result['success']) {
        _showSnackBar(result['message']);
        context.go('/total-clients');
      } else {
        _showSnackBar(result['message'], isError: true);
      }
    } catch (e) {
      print('🟨 Error --- $e');
      setState(() => _isLoading = false);
      _showSnackBar('An error occurred: $e', isError: true);
    }
  }

  Widget _buildImageContainer() {
    if (_selectedImagePath != null ||
        (_existingImageBase64 != null && _existingImageBase64!.isNotEmpty)) {
      // Avatar with image
      return Container(
        width: 100.w,
        height: 100.w,
        decoration: BoxDecoration(
          color: Color(0xFFF7F7F7), // var(--800)
          borderRadius: BorderRadius.circular(100.r),
        ),
        child: _buildImagePreview(),
      );
    } else {
      // Full width card with fallback text

      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // SVG with white circular background
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(8.w), // optional padding for SVG
                  child: SvgPicture.asset(
                    'assets/icons/svg/picker-user-round.svg', // replace with your svg path
                    width: 48.w,
                    height: 48.h,
                  ),
                ),
                SizedBox(height: 12.h),
                // Upload text
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 12.h,
                      horizontal: 16.w,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xCC090F05), // var(--transparent-black-80)
                      borderRadius: BorderRadius.circular(32.r),
                    ),
                    child: Text(
                      'Upload Photo (optional)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildImagePreview() {
    final double size = 72.w; // width & height

    if (_selectedImagePath != null) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100), // circular
          child: Image.file(
            File(_selectedImagePath!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
        ),
      );
    } else if (_existingImageBase64 != null &&
        _existingImageBase64!.isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Image.memory(
            const Base64Decoder().convert(_existingImageBase64!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: size,
        height: size,
        child: const SizedBox.shrink(), // fallback handled elsewhere
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: _isEditMode ? 'Edit Client' : 'Add New Client',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile image picker
              Stack(
                alignment: Alignment.bottomRight,
                children: [_buildImageContainer()],
              ),

              SizedBox(height: 8.h),

              if (_isEditMode)
                GestureDetector(
                  onTap: _pickImage,
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
                        height: 1.3, // line-height: 130%
                        letterSpacing: -0.01 * 10, // letter-spacing: -1%
                      ),
                    ),
                  ),
                ),

              SizedBox(height: 20.h),

              // Name fields
              Row(
                children: [
                  Expanded(
                    child: custom.TextField(
                      controller: firstNameController,
                      label: 'First Name',
                      hint: 'Kristina',
                      prefixIconSvg: 'assets/icons/svg/user.svg',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'First name is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: custom.TextField(
                      controller: lastNameController,
                      label: 'Last Name',
                      hint: 'Mehta',
                      prefixIconSvg: 'assets/icons/svg/user.svg',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Last name is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Email
              custom.TextField(
                controller: emailController,
                label: 'Email',
                hint: 'jonjons@gmail.com',
                prefixIconSvg: 'assets/icons/svg/mail.svg',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Phone
              custom.TextField(
                controller: phoneController,
                label: 'Phone',
                hint: '(555) 247-8391',
                prefixIconSvg: 'assets/icons/svg/call.svg',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: Text(
                            'Client Type',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary.withOpacity(0.8),
                            ),
                          ),
                        ),

                        // Dropdown Button
                        SelectablePopupMenu(
                          customIcon: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 14.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(100.r),
                              border: Border.all(
                                color: AppColors.textPrimary.withOpacity(0.05),
                                width: 1.25,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    (clientType == null ||
                                            clientType == 'Client type')
                                        ? 'Client Type'
                                        : clientType!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          (clientType == null ||
                                              clientType == 'Client type')
                                          ? Color(0xFF999999)
                                          : AppColors.textPrimary.withOpacity(
                                              0.9,
                                            ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 24.r,
                                  color: AppColors.textPrimary.withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                          offset: Offset(0, 8),
                          menuWidth:
                              null, // Will use the width of the trigger button
                          items: clientTypes.map((type) {
                            return SelectableMenuItemData(
                              text: type,
                              isSelected: clientType == type,
                              onPressed: () {
                                setState(() => clientType = type);
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // Join Date
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectDate,
                      child: AbsorbPointer(
                        child: custom.TextField(
                          controller: joinDateController,
                          label: 'Join Date',
                          hint: 'Nov 21, 2025',
                          prefixIconSvg: 'assets/icons/svg/calendar.svg',
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // Social Media Section
              // Instagram & TikTok (Row 1)
              Row(
                children: [
                  Expanded(
                    child: custom.TextField(
                      controller: instagramController,
                      label: 'Instagram',
                      hint: '@username',
                      prefixIconSvg: 'assets/icons/svg/insta.svg',
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: custom.TextField(
                      controller: tiktokController,
                      label: 'TikTok',
                      hint: '@username',
                      prefixIconSvg: 'assets/icons/svg/tik.svg',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // LinkedIn & Twitter (Row 2)
              Row(
                children: [
                  Expanded(
                    child: custom.TextField(
                      controller: linkedinController,
                      label: 'LinkedIn',
                      hint: '@username',
                      prefixIconSvg: 'assets/icons/svg/link.svg',
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: custom.TextField(
                      controller: twitterController,
                      label: 'Twitter',
                      hint: '@username',
                      prefixIconSvg: 'assets/icons/svg/twitter.svg',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32.h),

              // Submit Button
              Button(
                onPressed: _isLoading ? null : _submitForm,
                text: _isEditMode ? 'Update' : 'Save',
                height: 54.h,
                borderRadius: BorderRadius.circular(32.r),
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                textColor: Colors.white,
                backgroundColor: AppColors.brand500,
                isLoading: _isLoading,
              ),
              SizedBox(height: 16.h),

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
            ],
          ),
        ),
      ),
    );
  }
}
