// lib/features/notifications/presentation/screens/notifications_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/custom_appbar.dart';

class NotificationItem {
  final String icon;
  final String title;
  final String subtitle;
  final DateTime timestamp;

  NotificationItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });
}

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationItem> notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final firestoreNotifications = await _notificationService
          .loadNotificationsFromFirestore(userId);

      setState(() {
        notifications = firestoreNotifications.map((data) {
          return NotificationItem(
            icon: data['icon'] as String,
            title: data['title'] as String,
            subtitle: data['subtitle'] as String,
            timestamp: data['timestamp'] as DateTime,
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  Map<String, List<NotificationItem>> _groupNotificationsByDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<NotificationItem>> groups = {};

    for (final item in notifications) {
      final itemDate = DateTime(
        item.timestamp.year,
        item.timestamp.month,
        item.timestamp.day,
      );
      String label;

      if (itemDate == today) {
        label = 'Today';
      } else if (itemDate == yesterday) {
        label = 'Yesterday';
      } else if (itemDate.isAfter(today.subtract(const Duration(days: 7)))) {
        label = DateFormat('EEEE').format(itemDate);
      } else {
        label = DateFormat('MMM dd, yyyy').format(itemDate);
      }

      groups.putIfAbsent(label, () => []).add(item);
    }

    final sortedKeys = <String>[];
    if (groups.containsKey('Today')) sortedKeys.add('Today');
    if (groups.containsKey('Yesterday')) sortedKeys.add('Yesterday');
    final otherKeys =
        groups.keys.where((k) => k != 'Today' && k != 'Yesterday').toList()
          ..sort((a, b) {
            final dateA = _parseDateLabel(a);
            final dateB = _parseDateLabel(b);
            return dateB.compareTo(dateA);
          });
    sortedKeys.addAll(otherKeys);

    return {for (final key in sortedKeys) key: groups[key]!};
  }

  DateTime _parseDateLabel(String label) {
    try {
      if (label.contains(',')) {
        return DateFormat('MMM dd, yyyy').parse(label);
      } else {
        final now = DateTime.now();
        for (int i = 0; i < 7; i++) {
          final date = now.subtract(Duration(days: i));
          if (DateFormat('EEEE').format(date) == label) {
            return date;
          }
        }
        return DateTime(2000);
      }
    } catch (e) {
      return DateTime(2000);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(title: 'Notifications'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final grouped = _groupNotificationsByDate();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: 'Notifications'),
      body: grouped.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.only(
                top: 24.0.h,
                bottom: MediaQuery.of(context).padding.bottom,
              ),
              itemCount: grouped.length,
              itemBuilder: (context, groupIndex) {
                final label = grouped.keys.elementAt(groupIndex);
                final items = grouped[label]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary.withOpacity(0.7),
                        ),
                      ),
                    ),
                    ...List.generate(items.length, (index) {
                      final isLast = index == items.length - 1;
                      return _buildNotificationCard(
                        items[index],
                        showBorder: !isLast,
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildNotificationCard(
    NotificationItem item, {
    required bool showBorder,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 0.w),
      decoration: BoxDecoration(
        border: showBorder
            ? Border(
                bottom: BorderSide(
                  color: AppColors.textSecondary.withOpacity(0.05),
                  width: 1.w,
                ),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 35.w,
            height: 35.w,
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Center(child: SvgPicture.asset(item.icon)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textPrimary.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            DateFormat('h:mm a').format(item.timestamp),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/svg/empty.svg',
              width: 80.w,
              height: 80.w,
            ),
            SizedBox(height: 24.h),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 300, // <-- your max width
              ),
              child: Text(
                'Your notification will appear here once you’ve received them.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
