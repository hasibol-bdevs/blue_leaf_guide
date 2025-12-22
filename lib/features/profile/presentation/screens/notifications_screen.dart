import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/button.dart';
import '../../../../shared/widgets/custom_appbar.dart';
import '../../../auth/providers/auth_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isNotification1 = true;
  bool _isGoalRemindersEnabled = false;
  int _selectedHour = 10;
  int _selectedMinute = 45;
  String _selectedPeriod = "AM";
  bool _isLoading = true;

  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final settings = await _notificationService.loadReminderSettings();
      final pushEnabled = await _notificationService
          .isPushNotificationEnabled();

      final enabled = settings['enabled'] as bool;
      final hour24 = settings['hour'] as int;
      final minute = settings['minute'] as int;

      final is12Hour = hour24 > 12;
      final hour12 = is12Hour ? hour24 - 12 : (hour24 == 0 ? 12 : hour24);
      final period = hour24 >= 12 ? "PM" : "AM";

      setState(() {
        _isNotification1 = pushEnabled;
        _isGoalRemindersEnabled = enabled;
        _selectedHour = hour12;
        _selectedMinute = minute;
        _selectedPeriod = period;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading settings: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Convert 12-hour format to 24-hour format
  int _convertTo24Hour(int hour12, String period) {
    if (period == "AM") {
      return hour12 == 12 ? 0 : hour12;
    } else {
      return hour12 == 12 ? 12 : hour12 + 12;
    }
  }

  /// Get formatted time string
  String _getFormattedTime() {
    return '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')} $_selectedPeriod';
  }

  /// Toggle goal reminders on/off
  Future<void> _toggleGoalReminders(bool value) async {
    setState(() => _isGoalRemindersEnabled = value);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.currentUser?.uid;

    if (uid == null) {
      _showErrorSnackBar('Please sign in to enable reminders');
      setState(() => _isGoalRemindersEnabled = false);
      return;
    }

    try {
      final hour24 = _convertTo24Hour(_selectedHour, _selectedPeriod);

      // Save locally
      await _notificationService.saveReminderSettings(
        enabled: value,
        hour: hour24,
        minute: _selectedMinute,
      );

      // Save to Firestore
      await _notificationService.saveReminderToFirestore(
        uid: uid,
        enabled: value,
        hour: hour24,
        minute: _selectedMinute,
      );

      if (value) {
        // Schedule notification
        await _notificationService.scheduleGoalReminder(
          hour: hour24,
          minute: _selectedMinute,
        );
        _showSuccessSnackBar('Goal reminder enabled at ${_getFormattedTime()}');
      } else {
        // Cancel notification
        await _notificationService.cancelGoalReminder();
        _showSuccessSnackBar('Goal reminder disabled');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update reminder settings');
      setState(() => _isGoalRemindersEnabled = !value);
    }
  }

  /// Update reminder time
  Future<void> _updateReminderTime(int hour, int minute, String period) async {
    setState(() {
      _selectedHour = hour;
      _selectedMinute = minute;
      _selectedPeriod = period;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.currentUser?.uid;

    if (uid == null) return;

    try {
      final hour24 = _convertTo24Hour(hour, period);

      // Save locally
      await _notificationService.saveReminderSettings(
        enabled: _isGoalRemindersEnabled,
        hour: hour24,
        minute: minute,
      );

      // Save to Firestore
      await _notificationService.saveReminderToFirestore(
        uid: uid,
        enabled: _isGoalRemindersEnabled,
        hour: hour24,
        minute: minute,
      );

      // Reschedule notification if enabled
      if (_isGoalRemindersEnabled) {
        await _notificationService.scheduleGoalReminder(
          hour: hour24,
          minute: minute,
        );
        _showSuccessSnackBar('Reminder time updated to ${_getFormattedTime()}');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update reminder time');
    }
  }

  void _openCustomTimePicker(BuildContext context) {
    int tempHour = _selectedHour;
    int tempMinute = _selectedMinute;
    String tempPeriod = _selectedPeriod;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Container(
            height: 300.h,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Column(
              children: [
                Text(
                  "Get Reminder",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 12.h),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        /// HOUR PICKER
                        SizedBox(
                          width: 60.w,
                          child: CupertinoPicker(
                            itemExtent: 32.h,
                            scrollController: FixedExtentScrollController(
                              initialItem: tempHour - 1,
                            ),
                            onSelectedItemChanged: (index) {
                              tempHour = index + 1;
                            },
                            children: List.generate(12, (i) {
                              final hour = i + 1;
                              return Center(
                                child: Text(
                                  hour.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        Text(
                          ":",
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        /// MINUTE PICKER
                        SizedBox(
                          width: 60.w,
                          child: CupertinoPicker(
                            itemExtent: 32.h,
                            scrollController: FixedExtentScrollController(
                              initialItem: tempMinute,
                            ),
                            onSelectedItemChanged: (index) {
                              tempMinute = index;
                            },
                            children: List.generate(60, (i) {
                              return Center(
                                child: Text(
                                  i.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        /// AM/PM PICKER
                        SizedBox(
                          width: 60.w,
                          child: CupertinoPicker(
                            itemExtent: 32.h,
                            scrollController: FixedExtentScrollController(
                              initialItem: tempPeriod == "AM" ? 0 : 1,
                            ),
                            onSelectedItemChanged: (index) {
                              tempPeriod = index == 0 ? "AM" : "PM";
                            },
                            children: const [
                              Center(child: Text("AM")),
                              Center(child: Text("PM")),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Padding(
                  padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 12.h),
                  child: Column(
                    children: [
                      Button(
                        onPressed: () {
                          _updateReminderTime(tempHour, tempMinute, tempPeriod);
                          Navigator.pop(context);
                        },
                        text: 'Save',
                        height: 54.h,
                        borderRadius: BorderRadius.circular(32.r),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        textColor: Colors.white,
                        backgroundColor: AppColors.brand500,
                      ),
                      SizedBox(height: 12.h),
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
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const CustomAppBar(title: 'Notifications'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Notifications'),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          children: [
            _buildNotificationItem(
              title: 'Push Notifications',
              subtitle: 'Receive app notification',
              switchValue: _isNotification1,
              onSwitchChanged: (value) async {
                setState(() {
                  _isNotification1 = value;
                });
                await _notificationService.savePushNotificationEnabled(value);
              },
            ),
            // Divider(color: AppColors.neutral50, thickness: 1.w, height: 1.h),
            // _buildNotificationItem(
            //   title: 'Goal Reminders',
            //   subtitle: 'Track monthly goal progress',
            //   switchValue: _isGoalRemindersEnabled,
            //   onSwitchChanged: _toggleGoalReminders,
            // ),
            // Divider(color: AppColors.neutral50, thickness: 1.w, height: 1.h),
            // _buildNotificationItem(
            //   title: 'Everyday',
            //   subtitle: '',
            //   isTimeItem: true,
            //   time: _getFormattedTime(),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    String? subtitle,
    bool? switchValue,
    ValueChanged<bool>? onSwitchChanged,
    bool isTimeItem = false,
    String? time,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: subtitle == null || subtitle.isEmpty
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textPrimary.withOpacity(0.7),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          isTimeItem
              ? GestureDetector(
                  onTap: () {
                    _openCustomTimePicker(context);
                  },
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/svg/reminder.svg',
                        width: 16.sp,
                        height: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        time ?? '',
                        style: TextStyle(
                          color: AppColors.textPrimary.withOpacity(0.8),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : CustomSwitch(value: switchValue!, onChanged: onSwitchChanged!),
        ],
      ),
    );
  }
}

class CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44.w,
        height: 26.h,
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: value
              ? AppColors.brand500
              : AppColors.textPrimary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(50.r),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20.w,
                height: 20.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x16330014),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: value
                    ? Center(
                        child: Icon(
                          Icons.check,
                          color: AppColors.brand500,
                          size: 16.sp,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
