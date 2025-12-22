// lib/shared/widgets/custom_popup_menu.dart
import 'package:blue_leaf_guide/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ==================== FULLY CUSTOM POPUP MENU ====================
class CustomPopupMenu extends StatefulWidget {
  final List<PopupMenuItemData> items;
  final String? iconPath;
  final Widget? customIcon;
  final Offset offset;
  final double? menuWidth;

  const CustomPopupMenu({
    Key? key,
    required this.items,
    this.iconPath,
    this.customIcon,
    this.offset = const Offset(-20, 0),
    this.menuWidth,
  }) : super(key: key);

  @override
  State<CustomPopupMenu> createState() => _CustomPopupMenuState();
}

class _CustomPopupMenuState extends State<CustomPopupMenu> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  void _showMenu() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;
    final menuWidth = widget.menuWidth ?? 140.w;

    // Calculate left position, ensuring menu doesn't overflow screen
    double leftPosition = offset.dx + widget.offset.dx;
    if (leftPosition + menuWidth > screenWidth - 16.w) {
      leftPosition = screenWidth - menuWidth - 16.w;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _hideMenu,
        child: Stack(
          children: [
            // Transparent barrier
            Positioned.fill(child: Container(color: Colors.transparent)),
            // Menu
            Positioned(
              left: leftPosition,
              top: offset.dy + size.height + widget.offset.dy,
              child: Material(
                color: Colors.transparent,
                child: _CustomMenuContent(
                  items: widget.items,
                  onItemPressed: (index) {
                    _hideMenu();
                    widget.items[index].onPressed();
                  },
                  menuWidth: widget.menuWidth,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _showMenu,
        child:
            widget.customIcon ??
            SvgPicture.asset(
              widget.iconPath ?? 'assets/icons/svg/more.svg',
              width: 24.w,
              height: 24.h,
            ),
      ),
    );
  }
}

class _CustomMenuContent extends StatelessWidget {
  final List<PopupMenuItemData> items;
  final Function(int) onItemPressed;
  final double? menuWidth;

  const _CustomMenuContent({
    required this.items,
    required this.onItemPressed,
    this.menuWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: menuWidth ?? 140.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            items.length,
            (index) => _CustomMenuItem(
              item: items[index],
              isLast: index == items.length - 1,
              onPressed: () => onItemPressed(index),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomMenuItem extends StatefulWidget {
  final PopupMenuItemData item;
  final bool isLast;
  final VoidCallback onPressed;

  const _CustomMenuItem({
    required this.item,
    required this.isLast,
    required this.onPressed,
  });

  @override
  State<_CustomMenuItem> createState() => _CustomMenuItemState();
}

class _CustomMenuItemState extends State<_CustomMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: widget.onPressed,
          onHover: (hovering) {
            setState(() => _isHovered = hovering);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            color: _isHovered
                ? AppColors.textPrimary.withOpacity(0.03)
                : Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.item.icon != null) ...[
                  widget.item.icon!,
                  SizedBox(width: 8.w),
                ],
                Text(
                  widget.item.text,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                    color:
                        widget.item.textColor ??
                        AppColors.textPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!widget.isLast)
          Divider(
            height: 1.h,
            thickness: 1.h,
            color: AppColors.textPrimary.withOpacity(0.05),
            indent: 0,
            endIndent: 0,
          ),
      ],
    );
  }
}

// ==================== SELECTABLE CUSTOM POPUP MENU ====================
class SelectablePopupMenu extends StatefulWidget {
  final List<SelectableMenuItemData> items;
  final String? iconPath;
  final Widget? customIcon;
  final Offset offset;
  final double? menuWidth;

  const SelectablePopupMenu({
    Key? key,
    required this.items,
    this.iconPath,
    this.customIcon,
    this.offset = const Offset(-20, 0),
    this.menuWidth,
  }) : super(key: key);

  @override
  State<SelectablePopupMenu> createState() => _SelectablePopupMenuState();
}

class _SelectablePopupMenuState extends State<SelectablePopupMenu> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  void _showMenu() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;
    final menuWidth =
        widget.menuWidth ??
        size.width; // Use button width if menuWidth not specified

    // Calculate left position, ensuring menu doesn't overflow screen
    double leftPosition = offset.dx + widget.offset.dx;
    if (leftPosition + menuWidth > screenWidth - 16.w) {
      leftPosition = screenWidth - menuWidth - 16.w;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _hideMenu,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            Positioned(
              left: leftPosition,
              top: offset.dy + size.height + widget.offset.dy,
              width: menuWidth, // Add width constraint
              child: Material(
                color: Colors.transparent,
                child: _SelectableMenuContent(
                  items: widget.items,
                  onItemPressed: (index) {
                    _hideMenu();
                    widget.items[index].onPressed();
                  },
                  menuWidth: menuWidth, // Pass the width
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _showMenu,
        child:
            widget.customIcon ??
            SvgPicture.asset(
              widget.iconPath ?? 'assets/icons/svg/filter.svg',
              width: 24.w,
              height: 24.h,
            ),
      ),
    );
  }
}

class _SelectableMenuContent extends StatelessWidget {
  final List<SelectableMenuItemData> items;
  final Function(int) onItemPressed;
  final double? menuWidth;

  const _SelectableMenuContent({
    required this.items,
    required this.onItemPressed,
    this.menuWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: menuWidth ?? 160.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            items.length,
            (index) => _SelectableMenuItem(
              item: items[index],
              isLast: index == items.length - 1,
              onPressed: () => onItemPressed(index),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectableMenuItem extends StatefulWidget {
  final SelectableMenuItemData item;
  final bool isLast;
  final VoidCallback onPressed;

  const _SelectableMenuItem({
    required this.item,
    required this.isLast,
    required this.onPressed,
  });

  @override
  State<_SelectableMenuItem> createState() => _SelectableMenuItemState();
}

class _SelectableMenuItemState extends State<_SelectableMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: widget.onPressed,
          onHover: (hovering) {
            setState(() => _isHovered = hovering);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            color: _isHovered
                ? AppColors.textPrimary.withOpacity(0.03)
                : Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.item.text,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                    color:
                        widget.item.textColor ??
                        AppColors.textPrimary.withOpacity(0.8),
                  ),
                ),
                if (widget.item.isSelected)
                  SvgPicture.asset(
                    widget.item.checkIconPath ?? 'assets/icons/svg/tick.svg',
                    width: 16.w,
                    height: 16.h,
                  )
                else
                  SizedBox(width: 16.w),
              ],
            ),
          ),
        ),
        if (!widget.isLast)
          Divider(
            height: 1.h,
            thickness: 1.h,
            color: AppColors.textPrimary.withOpacity(0.05),
            indent: 0,
            endIndent: 0,
          ),
      ],
    );
  }
}

// ==================== DATA MODELS ====================
class PopupMenuItemData {
  final String text;
  final VoidCallback onPressed;
  final Color? textColor;
  final Widget? icon;

  PopupMenuItemData({
    required this.text,
    required this.onPressed,
    this.textColor,
    this.icon,
  });
}

class SelectableMenuItemData {
  final String text;
  final VoidCallback onPressed;
  final Color? textColor;
  final bool isSelected;
  final String? checkIconPath;

  SelectableMenuItemData({
    required this.text,
    required this.onPressed,
    this.textColor,
    required this.isSelected,
    this.checkIconPath,
  });
}

// ==================== USAGE EXAMPLES ====================
// 
// ========== 1. SIMPLE MENU (Edit/Delete) ==========
//
// CustomPopupMenu(
//   iconPath: 'assets/icons/svg/more.svg',
//   offset: Offset(-100, 8), // Adjust position
//   menuWidth: 140.w, // Custom width
//   items: [
//     PopupMenuItemData(
//       text: 'Edit',
//       textColor: AppColors.textPrimary.withOpacity(0.8),
//       icon: Icon(Icons.edit, size: 16.r, color: AppColors.textPrimary),
//       onPressed: () {
//         context.push('/add-client', extra: {...});
//       },
//     ),
//     PopupMenuItemData(
//       text: 'Delete',
//       textColor: AppColors.errorRed,
//       icon: Icon(Icons.delete, size: 16.r, color: AppColors.errorRed),
//       onPressed: () {
//         _showDeleteDialog(context, clientId);
//       },
//     ),
//   ],
// ),
//
// ========== 2. SELECTABLE MENU (With Checkmarks) ==========
//
// SelectablePopupMenu(
//   iconPath: 'assets/icons/svg/filter.svg',
//   offset: Offset(-120, 8),
//   menuWidth: 180.w,
//   items: [
//     SelectableMenuItemData(
//       text: 'All Clients',
//       isSelected: true,
//       onPressed: () { /* Handle filter */ },
//     ),
//     SelectableMenuItemData(
//       text: 'Active Only',
//       isSelected: false,
//       onPressed: () { /* Handle filter */ },
//     ),
//   ],
// ),
//
// ========== 3. CUSTOM ICON BUTTON ==========
//
// CustomPopupMenu(
//   customIcon: Container(
//     padding: EdgeInsets.all(8.r),
//     decoration: BoxDecoration(
//       color: AppColors.brand500,
//       shape: BoxShape.circle,
//     ),
//     child: Icon(Icons.more_vert, color: Colors.white, size: 20.r),
//   ),
//   items: [...],
// ),