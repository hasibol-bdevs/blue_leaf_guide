import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../growth/presentation/screens/growth_screen.dart';
import '../../../roadmap/presentation/screens/roadmap_screen.dart';
import '../../../task/presentation/screens/task_screen.dart';
import '../../providers/navigation_provider.dart';
import '../screens/home_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialTab;
  const MainNavigationScreen({super.key, this.initialTab = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize the provider with the initial tab from the route
    Future.microtask(() {
      context.read<NavigationProvider>().setTab(widget.initialTab);
    });
  }

  @override
  void didUpdateWidget(MainNavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update tab when initialTab changes (from route parameters)
    if (oldWidget.initialTab != widget.initialTab) {
      context.read<NavigationProvider>().setTab(widget.initialTab);
    }
  }

  // Placeholder screens for other tabs
  final List<Widget> _screens = [
    const HomeScreen(),
    GrowthScreen(),
    RoadmapScreen(),
    TaskScreen(),
    ChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.watch<NavigationProvider>().currentTab;
    return Scaffold(
      key: ValueKey(widget.initialTab),
      body: _screens[currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.brand50, width: 1)),
          boxShadow: [
            BoxShadow(
              color: const Color(0x14332200),
              blurRadius: 42,
              offset: const Offset(0, -16),
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          bottom: true,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: 'assets/icons/svg/home.svg',
                  activeIcon: 'assets/icons/svg/home-active.svg',
                  label: 'Home',
                ),
                _buildNavItem(
                  index: 1,
                  icon: 'assets/icons/svg/progress.svg',

                  activeIcon: 'assets/icons/svg/progress-active.svg',
                  label: 'Growth',
                ),
                _buildNavItem(
                  index: 2,
                  icon: 'assets/icons/svg/map.svg',

                  activeIcon: 'assets/icons/svg/map-active.svg',
                  label: 'Roadmap',
                ),
                _buildNavItem(
                  index: 3,
                  icon: 'assets/icons/svg/check-round.svg',

                  activeIcon: 'assets/icons/svg/check-round-active.svg',
                  label: 'Task',
                ),
                _buildNavItem(
                  index: 4,
                  icon: 'assets/icons/svg/tutor.svg',

                  activeIcon: 'assets/icons/svg/tutor-active.svg',
                  label: 'AI Tutor',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String icon,
    required String activeIcon,
    required String label,
  }) {
    final isActive = context.watch<NavigationProvider>().currentTab == index;

    return GestureDetector(
      onTap: () {
        if (index == 4) {
          context.push('/chat');
        } else {
          context.read<NavigationProvider>().setTab(index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              isActive ? activeIcon : icon,
              width: 24.sp,
              height: 24.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? AppColors.brand500
                    : AppColors.textSecondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder screen for other tabs
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_outlined,
              size: 64.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              '$title Screen',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
