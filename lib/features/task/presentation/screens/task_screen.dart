import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/custom_segment_tab.dart';
import '../../../../shared/widgets/custom_title_subtitle_appbar.dart';
import 'check_in_screen.dart';
import 'daily_task_screen.dart';
import 'monthly_goal_screen.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String title = "Tasks & Goals";
  String subtitle = "Track your daily activities and monthly goals";

  final List<String> tabs = ["Daily Task", "Check-in", "Monthly Goal"];
  final List<String> subtitles = [
    "Manage your daily tasks",
    "Check your progress",
    "Track your monthly goals",
  ];

  // Update your initState and listener:
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _updateTitleSubtitle(_tabController.index);
      });
    });
  }

  // Add this method:
  void _updateTitleSubtitle(int index) {
    switch (index) {
      case 0: // Daily Task
        title = "Tasks & Goals";
        subtitle = "Track your daily activities and monthly goals";
        break;
      case 1: // Check-in
        title = "Daily Check-in";
        subtitle = DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now());
        break;
      case 2: // Monthly Goal
        title = "Tasks & Goals";
        subtitle = "Track your daily activities and monthly goals";
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomTitleSubtitleAppbar(title: title, subtitle: subtitle),

      body: Column(
        children: [
          Expanded(
            child: CustomSegmentTab(
              tabs: tabs,
              tabViews: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: DailyTaskScreen(),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: CheckInScreen(),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: MonthlyGoalScreen(),
                ),
              ],
              // Pass the same TabController so we can listen for index changes
              controller: _tabController,
            ),
          ),
        ],
      ),
    );
  }
}
