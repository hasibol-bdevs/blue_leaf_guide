import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/custom_date_picker_dialog.dart';
import '../../../../shared/widgets/profile_item.dart';

class DailyTaskScreen extends StatefulWidget {
  const DailyTaskScreen({super.key});

  @override
  State<DailyTaskScreen> createState() => _DailyTaskScreenState();
}

class _DailyTaskScreenState extends State<DailyTaskScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  late String _userId;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _tasks = [];
  List<bool> _switchValues = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user == null) {
      Navigator.of(context).pop();
      return;
    }
    _userId = user.uid;
    _loadData();
  }

  Future<void> _loadData() async {
    final standaloneDoc = await _firestore
        .collection('standalone')
        .doc('default')
        .get();

    if (!standaloneDoc.exists) {
      // Fallback to hardcoded tasks
      _tasks = [
        {
          "icon": "assets/icons/svg/fb.svg",
          "title": "Post on Facebook",
          "url": "https://www.facebook.com",
        },
        {
          "icon": "assets/icons/svg/insta.svg",
          "title": "Post on Instagram",
          "url": "https://www.instagram.com",
        },
        {
          "icon": "assets/icons/svg/tik.svg",
          "title": "Post on TikTok",
          "url": "https://www.tiktok.com",
        },
        {
          "icon": "assets/icons/svg/gallery.svg",
          "title": "Take picture of your work",
          "action": "camera",
        },
        {
          "icon": "assets/icons/svg/add.svg",
          "title": "Post pictures of your work",
        },
        {"icon": "assets/icons/svg/user-gradient.svg", "title": "Client serve"},
      ];
    } else {
      final data = standaloneDoc.data()!;
      _tasks = List<Map<String, dynamic>>.from(data['items'] ?? []);
    }

    _switchValues = List.generate(_tasks.length, (_) => false);
    await _loadUserTogglesForDate(_selectedDate);

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadUserTogglesForDate(DateTime date) async {
    final formattedDate = _formatDate(date);
    final doc = await _firestore
        .collection('daily_tasks')
        .doc(_userId)
        .collection('dates')
        .doc(formattedDate)
        .get();

    if (doc.exists) {
      final toggles = List<dynamic>.from(doc.data()?['toggles'] ?? []);
      _switchValues = List.generate(_tasks.length, (i) {
        if (i < toggles.length) return toggles[i] as bool;
        return false;
      });
    } else {
      _switchValues = List.generate(_tasks.length, (_) => false);
    }
  }

  Future<void> _saveToggle(int index, bool value) async {
    setState(() {
      _switchValues = List.from(_switchValues)..[index] = value;
    });

    final formattedDate = _formatDate(_selectedDate);

    try {
      await _firestore
          .collection('daily_tasks')
          .doc(_userId)
          .collection('dates')
          .doc(formattedDate)
          .set({
            'toggles': List.from(_switchValues),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (_isCurrentDateEditable && _switchValues.every((val) => val == true)) {
        final prefs = await SharedPreferences.getInstance();
        final today = _formatDate(DateTime.now());
        final notificationKey = 'daily_task_notification_$today';
        final notificationSent = prefs.getBool(notificationKey) ?? false;

        if (!notificationSent) {
          await _notificationService.showDailyTaskCompleteNotification(_userId);
          await prefs.setBool(notificationKey, true);
        }
      }
    } catch (e) {
      print('❌ Error saving toggle: $e');
    }
  }

  bool get _isCurrentDateEditable {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    return selected.isAtSameMomentAs(today);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formattedDateString(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]}, ${date.year}';
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      print('🔗 Launching URL: $urlString');
      final uri = Uri.parse(urlString);

      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to open $urlString')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Cannot open $urlString')));
        }
      }
    } catch (e) {
      print('❌ Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _takePicture() async {
    print('📸 Camera button tapped');

    final hasPermission = await _requestPermission();
    if (!hasPermission) {
      print('❌ Camera permission denied');
      return;
    }

    final ImagePicker picker = ImagePicker();
    try {
      print('📸 Opening camera...');
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        print("✅ Camera capture success: ${pickedFile.path}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo captured successfully!')),
          );
        }
      } else {
        print("ℹ️ Camera cancelled by user");
      }
    } catch (e) {
      print("❌ Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: ${e.toString()}')),
        );
      }
    }
  }

  Future<bool> _requestPermission() async {
    final permission = Permission.camera;
    final status = await permission.status;

    if (status.isGranted) {
      print('✅ Camera permission already granted');
      return true;
    }

    if (status.isDenied) {
      print('⚠️ Camera permission denied, requesting...');
      final result = await permission.request();

      if (result.isGranted) {
        print('✅ Camera permission granted');
        return true;
      }

      if (result.isPermanentlyDenied) {
        _showPermissionDeniedDialog('Camera');
        return false;
      }

      return false;
    }

    if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog('Camera');
      return false;
    }

    return false;
  }

  void _showPermissionDeniedDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text(
          '$permissionName permission is required to take photos. '
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

  @override
  Widget build(BuildContext context) {
    String formattedDate = _formattedDateString(_selectedDate);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary.withOpacity(0.8),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final todayNormalized = DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  );

                  final selected = await showDialog<DateTime>(
                    context: context,
                    builder: (_) => CustomDatePickerDialog(
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: todayNormalized,
                    ),
                  );

                  if (selected != null && selected != _selectedDate) {
                    setState(() {
                      _selectedDate = selected;
                      _loading = true;
                    });

                    await _loadUserTogglesForDate(selected);

                    if (mounted) {
                      setState(() {
                        _loading = false;
                      });
                    }
                  }
                },
                child: Container(
                  width: 45.w,
                  height: 45.h,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  padding: EdgeInsets.all(10.w),
                  child: SvgPicture.asset(
                    'assets/icons/svg/calendar.svg',
                    fit: BoxFit.contain,
                    width: 24.w,
                    height: 24.h,
                    colorFilter: ColorFilter.mode(
                      AppColors.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            itemCount: _tasks.length,
            separatorBuilder: (_, __) => SizedBox(height: 4.h),
            itemBuilder: (context, index) {
              final task = _tasks[index];

              // Determine the action - all items show arrow icon
              VoidCallback? onTrailingTap;

              if (task["url"] != null && (task["url"] as String).isNotEmpty) {
                // Has URL - open in browser
                onTrailingTap = () {
                  print('🔗 Arrow tapped for URL: ${task["title"]}');
                  _launchUrl(task["url"]!);
                };
              } else if (task["action"] == "camera") {
                // Has camera action - open camera
                onTrailingTap = () {
                  print('📸 Arrow tapped for camera: ${task["title"]}');
                  _takePicture();
                };
              } else if (index == _tasks.length - 1) {
                // Last item without URL or action - open camera by default
                onTrailingTap = () {
                  print('📸 Arrow tapped (last item): ${task["title"]}');
                  _takePicture();
                };
              }

              return ProfileItem(
                key: ValueKey('${_formatDate(_selectedDate)}-$index'),
                svgIconPath: task["icon"]!,
                iconBackgroundColor: Colors.blue.shade100,
                title: task["title"]!,
                value: _switchValues[index],
                onChanged: (val) => _saveToggle(index, val),
                showDivider: index != _tasks.length - 1,
                isEditable: _isCurrentDateEditable,
                trailingIconPath:
                    'assets/icons/svg/chevron-left.svg', // Always show arrow
                onTrailingIconTap: onTrailingTap,
              );
            },
          ),
        ),
      ],
    );
  }
}
