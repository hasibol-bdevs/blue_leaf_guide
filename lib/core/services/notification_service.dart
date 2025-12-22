import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Notification ID for goal reminders
  static const int _goalReminderNotificationId = 1;

  // SharedPreferences keys
  static const String _keyGoalReminderEnabled = 'goal_reminder_enabled';
  static const String _keyReminderHour = 'reminder_hour';
  static const String _keyReminderMinute = 'reminder_minute';

  // Add these constants with the existing ones:
  static const int _buildBrandCompleteNotificationId = 2;
  static const int _dailyTaskCompleteNotificationId = 3;
  static const int _roadmapCompleteNotificationId = 4;
  static const int _allRoadmapsCompleteNotificationId = 5;
  static const int _dailyTaskReminderNotificationId = 6;

  static const String _keyPushNotificationEnabled = 'push_notification_enabled';

  // /// Initialize the notification service
  // Future<void> initialize() async {
  //   // Initialize timezone data
  //   tz.initializeTimeZones();

  //   // Get device's local timezone
  //   final String timeZoneName = await _getLocalTimeZone();
  //   tz.setLocalLocation(tz.getLocation(timeZoneName));

  //   // Android initialization settings
  //   const AndroidInitializationSettings androidSettings =
  //       AndroidInitializationSettings('@mipmap/ic_launcher');

  //   // iOS initialization settings
  //   const DarwinInitializationSettings iosSettings =
  //       DarwinInitializationSettings(
  //         requestAlertPermission: true,
  //         requestBadgePermission: true,
  //         requestSoundPermission: true,
  //       );

  //   const InitializationSettings initSettings = InitializationSettings(
  //     android: androidSettings,
  //     iOS: iosSettings,
  //   );

  //   await _notifications.initialize(
  //     initSettings,
  //     onDidReceiveNotificationResponse: _onNotificationTapped,
  //   );

  //   // Request permissions for iOS
  //   await _requestPermissions();
  // }

  Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();

    final String timeZoneName = await _getLocalTimeZone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Android init
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS init (NO automatic permissions)
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // ❌ REMOVE this:
    // await _requestPermissions();
  }

  /// Get the device's local timezone name
  Future<String> _getLocalTimeZone() async {
    // Default to UTC if unable to determine
    try {
      final now = DateTime.now();
      final localOffset = now.timeZoneOffset;

      // Common timezone mappings based on offset
      final offsetHours = localOffset.inHours;

      // This is a simplified approach. For production, consider using
      // flutter_native_timezone package for accurate timezone detection
      final timezoneMap = {
        -5: 'America/New_York',
        -6: 'America/Chicago',
        -7: 'America/Denver',
        -8: 'America/Los_Angeles',
        0: 'Europe/London',
        1: 'Europe/Paris',
        6: 'Asia/Dhaka',
        5: 'Asia/Karachi',
        8: 'Asia/Shanghai',
        9: 'Asia/Tokyo',
      };

      return timezoneMap[offsetHours] ?? 'UTC';
    } catch (e) {
      return 'UTC';
    }
  }

  /// Request notification permissions (primarily for iOS)
  // ignore: unused_element
  Future<void> _requestPermissions() async {
    // ignore: unused_local_variable
    final bool? result = await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to goals screen, etc.
    print('Notification tapped: ${response.payload}');
  }

  /// Schedule daily goal reminder notification
  Future<void> scheduleGoalReminder({
    required int hour,
    required int minute,
  }) async {
    await cancelGoalReminder(); // Cancel any existing notification

    final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'goal_reminders',
          'Goal Reminders',
          channelDescription: 'Daily reminders to track your monthly goals',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      _goalReminderNotificationId,
      'Track Your Goals 🎯',
      'Don\'t forget to update your monthly goal progress today!',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );

    print(
      '✅ Goal reminder scheduled for ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
    );
  }

  /// Calculate the next instance of the specified time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the scheduled time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Cancel goal reminder notification
  Future<void> cancelGoalReminder() async {
    await _notifications.cancel(_goalReminderNotificationId);
    print('❌ Goal reminder cancelled');
  }

  /// Save reminder settings to SharedPreferences
  Future<void> saveReminderSettings({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGoalReminderEnabled, enabled);
    await prefs.setInt(_keyReminderHour, hour);
    await prefs.setInt(_keyReminderMinute, minute);
  }

  /// Load reminder settings from SharedPreferences
  Future<Map<String, dynamic>> loadReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool(_keyGoalReminderEnabled) ?? false,
      'hour': prefs.getInt(_keyReminderHour) ?? 10,
      'minute': prefs.getInt(_keyReminderMinute) ?? 45,
    };
  }

  /// Save reminder settings to Firestore
  Future<void> saveReminderToFirestore({
    required String uid,
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'reminderEnabled': enabled,
        'reminderHour': hour,
        'reminderMinute': minute,
        'reminderUpdatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Reminder settings saved to Firestore');
    } catch (e) {
      print('❌ Error saving to Firestore: $e');
    }
  }

  /// Load reminder settings from Firestore
  Future<Map<String, dynamic>?> loadReminderFromFirestore(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return {
          'enabled': data['reminderEnabled'] ?? false,
          'hour': data['reminderHour'] ?? 10,
          'minute': data['reminderMinute'] ?? 45,
        };
      }
    } catch (e) {
      print('❌ Error loading from Firestore: $e');
    }
    return null;
  }

  /// Sync reminder settings (Firestore -> Local -> Schedule)
  Future<void> syncReminderSettings(String uid) async {
    try {
      // Load from Firestore
      final firestoreSettings = await loadReminderFromFirestore(uid);

      if (firestoreSettings != null) {
        final enabled = firestoreSettings['enabled'] as bool;
        final hour = firestoreSettings['hour'] as int;
        final minute = firestoreSettings['minute'] as int;

        // Save to local storage
        await saveReminderSettings(
          enabled: enabled,
          hour: hour,
          minute: minute,
        );

        // Schedule notification if enabled
        if (enabled) {
          await scheduleGoalReminder(hour: hour, minute: minute);
        } else {
          await cancelGoalReminder();
        }

        print('✅ Reminder settings synced from Firestore');
      }
    } catch (e) {
      print('❌ Error syncing reminder settings: $e');
    }
  }

  /// Check if push notifications are enabled
  Future<bool> isPushNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPushNotificationEnabled) ?? true;
  }

  /// Save push notification setting
  Future<void> savePushNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPushNotificationEnabled, enabled);
  }

  /// Show immediate notification for Build Brand completion
  Future<void> showBuildBrandCompleteNotification(String uid) async {
    // Check if push notifications are enabled
    final pushEnabled = await isPushNotificationEnabled();
    if (!pushEnabled) {
      print('❌ Push notifications are disabled');
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'build_brand_complete',
          'Build Brand Completion',
          channelDescription:
              'Notifications for Build Brand milestone completion',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _buildBrandCompleteNotificationId,
      'Congratulations! 🎉',
      'You\'ve completed all Build Brand steps. Great job!',
      details,
      payload: 'build_brand_complete',
    );

    // Save notification to Firestore
    await _saveNotificationToFirestore(
      uid: uid,
      title: 'Congratulations! 🎉',
      subtitle: 'You\'ve completed all Build Brand steps. Great job!',
      icon: 'assets/icons/svg/bell.svg',
    );

    print('✅ Build Brand completion notification sent');
  }

  /// Save notification to Firestore
  Future<void> _saveNotificationToFirestore({
    required String uid,
    required String title,
    required String subtitle,
    required String icon,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .add({
            'title': title,
            'subtitle': subtitle,
            'icon': icon,
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
          });
      print('✅ Notification saved to Firestore');
    } catch (e) {
      print('❌ Error saving notification to Firestore: $e');
    }
  }

  /// Load notifications from Firestore
  Future<List<Map<String, dynamic>>> loadNotificationsFromFirestore(
    String uid,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'subtitle': data['subtitle'] ?? '',
          'icon': data['icon'] ?? 'assets/icons/svg/bell.svg',
          'timestamp':
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'read': data['read'] ?? false,
        };
      }).toList();
    } catch (e) {
      print('❌ Error loading notifications from Firestore: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String uid, String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  Future<void> showDailyTaskCompleteNotification(String uid) async {
    // Check if push notifications are enabled
    final pushEnabled = await isPushNotificationEnabled();
    if (!pushEnabled) {
      print('❌ Push notifications are disabled');
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_task_complete',
          'Daily Task Completion',
          channelDescription: 'Notifications for daily task completion',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _dailyTaskCompleteNotificationId,
      'Great Job! 🎉',
      'You\'ve completed all your daily tasks today!',
      details,
      payload: 'daily_task_complete',
    );

    // Save notification to Firestore
    await _saveNotificationToFirestore(
      uid: uid,
      title: 'Great Job! 🎉',
      subtitle: 'You\'ve completed all your daily tasks today!',
      icon: 'assets/icons/svg/bell.svg',
    );

    print('✅ Daily task completion notification sent');
  }

  /// Schedule automatic daily task reminder (always on, no toggle)
  Future<void> scheduleDailyTaskReminder() async {
    // Set default time: 9:00 AM
    const int defaultHour = 8;
    const int defaultMinute = 0;

    await _notifications.cancel(_dailyTaskReminderNotificationId);

    final tz.TZDateTime scheduledDate = _nextInstanceOfTime(
      defaultHour,
      defaultMinute,
    );

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_task_reminders',
          'Daily Task Reminders',
          channelDescription: 'Daily reminders to complete your tasks',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Array of motivational messages (one will be picked randomly each day)
    final messages = [
      'Start your day strong! Check off your daily tasks.',
      'Time to tackle today\'s goals! Let\'s make progress.',
      'Good morning! Your daily tasks are waiting for you.',
      'Rise and shine! Complete your tasks and build momentum.',
      'New day, new opportunities! Don\'t forget your daily tasks.',
      'Stay consistent! Your daily tasks help you succeed.',
      'Great things happen one task at a time. Let\'s go!',
      'Your future self will thank you. Complete your tasks today!',
    ];

    // Pick a random message
    final randomIndex = DateTime.now().millisecond % messages.length;
    final todayMessage = messages[randomIndex];

    await _notifications.zonedSchedule(
      _dailyTaskReminderNotificationId,
      'Daily Task Reminder ✨',
      todayMessage,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );

    print('✅ Daily task reminder scheduled for 9:00 AM every day');
  }

  /// Show notification for Roadmap completion
  Future<void> showRoadmapCompleteNotification(
    String uid,
    String roadmapTitle,
  ) async {
    // Check if push notifications are enabled
    final pushEnabled = await isPushNotificationEnabled();
    if (!pushEnabled) {
      print('❌ Push notifications are disabled');
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'roadmap_complete',
          'Roadmap Completion',
          channelDescription: 'Notifications for roadmap completion',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _roadmapCompleteNotificationId,
      'Milestone Achieved! 🎯',
      'You\'ve completed "$roadmapTitle". Keep up the great work!',
      details,
      payload: 'roadmap_complete',
    );

    // Save notification to Firestore
    await _saveNotificationToFirestore(
      uid: uid,
      title: 'Milestone Achieved! 🎯',
      subtitle: 'You\'ve completed "$roadmapTitle". Keep up the great work!',
      icon: 'assets/icons/svg/bell.svg',
    );

    print('✅ Roadmap completion notification sent for: $roadmapTitle');
  }

  Future<void> showAllRoadmapsCompleteNotification(String uid) async {
    // Check if push notifications are enabled
    final pushEnabled = await isPushNotificationEnabled();
    if (!pushEnabled) {
      print('❌ Push notifications are disabled');
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'all_roadmaps_complete',
          'All Roadmaps Completion',
          channelDescription: 'Notification when all roadmaps are completed',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _allRoadmapsCompleteNotificationId,
      'Amazing Achievement! 🎉🎯',
      'You\'ve completed all roadmaps! Your dedication is truly inspiring!',
      details,
      payload: 'all_roadmaps_complete',
    );

    // Save notification to Firestore
    await _saveNotificationToFirestore(
      uid: uid,
      title: 'Amazing Achievement! 🎉🎯',
      subtitle:
          'You\'ve completed all roadmaps! Your dedication is truly inspiring!',
      icon: 'assets/icons/svg/bell.svg',
    );

    print('✅ All roadmaps completion notification sent');
  }
}
