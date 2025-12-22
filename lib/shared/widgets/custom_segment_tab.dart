import 'package:blue_leaf_guide/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomSegmentTab extends StatefulWidget {
  final List<String> tabs;
  final List<Widget> tabViews;
  final Color activeColor;
  final Color backgroundColor;
  final Color textColor;
  final Color unselectedTextColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final TabController? controller;

  const CustomSegmentTab({
    super.key,
    required this.tabs,
    required this.tabViews,
    this.activeColor = AppColors.brand500,
    this.backgroundColor = const Color(
      0x0D000000,
    ), // AppColors.textPrimary.withOpacity(0.05)
    this.textColor = Colors.white,
    this.unselectedTextColor = Colors.black87,
    this.fontSize = 12.5,
    this.fontWeight = FontWeight.w600,
    this.borderRadius = 100,
    this.padding = const EdgeInsets.symmetric(horizontal: 2.0),
    this.controller,
  }) : assert(
         tabs.length == tabViews.length,
         'Tabs and TabViews length must be the same',
       );

  @override
  State<CustomSegmentTab> createState() => _CustomSegmentTabState();
}

class _CustomSegmentTabState extends State<CustomSegmentTab>
    with SingleTickerProviderStateMixin {
  late TabController _internalController;

  TabController get _controller => widget.controller ?? _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = TabController(
      length: widget.tabs.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _internalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 10.w),
          padding: widget.padding,

          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: TabBar(
            indicatorPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            controller: _controller,
            // isScrollable: true,
            indicator: BoxDecoration(
              color: widget.activeColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorColor: Colors.transparent,
            dividerColor: Colors.transparent,
            labelColor: widget.textColor,
            unselectedLabelColor: widget.unselectedTextColor,
            labelStyle: TextStyle(
              fontSize: widget.fontSize.sp,
              fontWeight: widget.fontWeight,
            ),
            tabs: widget.tabs.map((tab) => Tab(text: tab)).toList(),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: TabBarView(
            controller: _controller, // <-- use unified controller
            children: widget.tabViews,
          ),
        ),
      ],
    );
  }
}
