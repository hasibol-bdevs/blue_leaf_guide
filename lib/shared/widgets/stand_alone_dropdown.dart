import 'package:blue_leaf_guide/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StandaloneDropdown extends StatelessWidget {
  final String? value;
  final String label;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? labelColor;

  const StandaloneDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (label.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: labelColor ?? const Color(0xFF1A1A1A),
              ),
            ),
          ),

        // Dropdown Container
        GestureDetector(
          onTap: () => _showDropdownDialog(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white,
              borderRadius: BorderRadius.circular(100.r),
              border: Border.all(
                color: borderColor ?? AppColors.textPrimary.withOpacity(0.05),
                width: 1.25,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: (value == null || value!.contains('Client type'))
                          ? const Color(0xFF999999) // grey for placeholder
                          : (textColor ??
                                AppColors.textPrimary.withOpacity(
                                  0.9,
                                )), // black for actual value
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
        ),
      ],
    );
  }

  Future<void> _showDropdownDialog(BuildContext context) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          constraints: BoxConstraints(maxHeight: 400.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Header
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label.isNotEmpty ? 'Select $label' : 'Select Option',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(
                        Icons.close,
                        size: 24.r,
                        color: const Color(0xFF666666),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: const Color(0xFFE5E5E5)),

              // Options List
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  itemCount: items.length,
                  separatorBuilder: (ctx, index) =>
                      Divider(height: 1, color: const Color(0xFFF0F0F0)),
                  itemBuilder: (ctx, index) {
                    final item = items[index];
                    final isSelected = value == item;

                    return InkWell(
                      onTap: () => Navigator.pop(ctx, item),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                        color: isSelected
                            ? const Color(0xFFF5F5F5)
                            : Colors.transparent,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFF6366F1)
                                      : const Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check,
                                size: 20.r,
                                color: const Color(0xFF6366F1),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null) {
      onChanged(selected);
    }
  }
}

// Usage Example:
class DropdownExample extends StatefulWidget {
  const DropdownExample({super.key});

  @override
  State<DropdownExample> createState() => _DropdownExampleState();
}

class _DropdownExampleState extends State<DropdownExample> {
  String? clientType;
  final List<String> clientTypes = ['Regular', 'Premium', 'VIP', 'Enterprise'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dropdown Example')),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            StandaloneDropdown(
              value: clientType,
              label: 'Client Type',
              hint: 'Select Client Type',
              items: clientTypes,
              onChanged: (value) {
                setState(() => clientType = value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
