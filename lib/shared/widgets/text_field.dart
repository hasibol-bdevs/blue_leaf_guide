import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme/app_colors.dart';
import '../../app/utils/sizes.dart';

class TextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final VoidCallback? onChanged;
  final VoidCallback? onEditingComplete;
  final VoidCallback? onSuffixIconTap; // NEW - for password toggle
  final TextInputAction? textInputAction;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final TextCapitalization textCapitalization;
  final String? prefixIconSvg;
  final String? suffixIconSvg;
  final Widget? prefixIconWidget;

  final bool readOnly;
  final VoidCallback? onTap;
  final Color? labelBackgroundColor;
  final double? borderRadius;
  final Color? disabledBorderColor;
  final TextAlign? textAlign; // Add this to your TextField class

  const TextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
    this.onChanged,
    this.onEditingComplete,
    this.onSuffixIconTap,
    this.textInputAction,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.textCapitalization = TextCapitalization.none,
    this.prefixIconSvg,
    this.prefixIconWidget,
    this.suffixIconSvg,
    this.readOnly = false,
    this.onTap,
    this.labelBackgroundColor,
    this.borderRadius,
    this.disabledBorderColor,
    this.textAlign,
  });

  @override
  State<TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<TextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label.isNotEmpty) ...[
              Container(
                color: widget.labelBackgroundColor ?? Colors.transparent,
                padding: widget.labelBackgroundColor != null
                    ? EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h)
                    : null,
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Family/Font',
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.normal,
                    fontSize: 14.sp,
                    height: 1.4,
                    letterSpacing: -0.01,
                    color: AppColors.textPrimary.withOpacity(0.7),
                  ),
                ),
              ),
              SizedBox(height: 8.h), // Only add spacing if label exists
            ],

            Focus(
              onFocusChange: (hasFocus) {
                setState(() => _isFocused = hasFocus);
              },
              child: TextFormField(
                controller: widget.controller,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                readOnly: widget.readOnly,
                onTap: widget.onTap,
                validator: widget.validator,
                enabled: widget.enabled,
                maxLines: widget.obscureText ? 1 : widget.maxLines,
                minLines: widget.minLines,
                textInputAction: widget.textInputAction,
                textCapitalization: widget.textCapitalization,
                textAlignVertical: TextAlignVertical.center,
                textAlign: widget.textAlign ?? TextAlign.start,
                onChanged: widget.onChanged != null
                    ? (_) => widget.onChanged!()
                    : null,
                onEditingComplete: widget.onEditingComplete,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  overflow: TextOverflow.ellipsis,
                ),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyle(
                    color: AppColors.textPrimary.withOpacity(0.3),
                    fontSize: AppFontSize.s14,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: 16.w + 20.r + 8.w,
                    minHeight: 12.h + 20.r + 12.h,
                  ),
                  prefixIcon:
                      (widget.prefixIconWidget != null ||
                          widget.prefixIconSvg != null ||
                          widget.icon != null)
                      ? Padding(
                          padding: EdgeInsets.only(
                            left: 16.w,
                            right: 8.w,
                            top: 12.h,
                            bottom: 12.h,
                          ),
                          child: _buildPrefixIcon(),
                        )
                      : null,
                  suffixIconConstraints: BoxConstraints(
                    minWidth: 8.w + 20.r + 16.w,
                    minHeight: 12.h + 20.r + 12.h,
                  ),
                  suffixIcon:
                      (widget.suffixIconSvg != null ||
                          widget.suffixIcon != null ||
                          widget.onSuffixIconTap != null)
                      ? Padding(
                          padding: EdgeInsets.only(
                            left: 8.w,
                            right: 16.w,
                            top: 12.h,
                            bottom: 12.h,
                          ),
                          child: _buildSuffixIcon(),
                        )
                      : null,
                  filled: true,
                  fillColor: widget.enabled
                      ? AppColors.background.withOpacity(0.5)
                      : AppColors.lightGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100.r),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100.r),
                    borderSide: BorderSide(
                      color: AppColors.neutral10.withOpacity(0.05),
                      width: 1.25.w,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100.r),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1.25.w,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100.r),
                    borderSide: BorderSide(
                      color: AppColors.errorRed,
                      width: 1.25.w,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100.r),
                    borderSide: BorderSide(
                      color: AppColors.errorRed,
                      width: 1.25.w,
                    ),
                  ),

                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100.r),
                    borderSide: BorderSide(
                      color:
                          widget.disabledBorderColor ??
                          AppColors.textPrimary.withOpacity(0.05),
                      width: 1.25.w,
                    ),
                  ),

                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppPadding.p16,
                    vertical: 16.h,
                  ),
                  errorStyle: TextStyle(
                    fontSize: AppFontSize.s12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrefixIcon() {
    if (widget.prefixIconWidget != null) {
      return SizedBox(
        width: 20.r,
        height: 20.r,
        child: widget.prefixIconWidget,
      );
    }

    if (widget.prefixIconSvg != null) {
      return SvgPicture.asset(widget.prefixIconSvg!, width: 20.r, height: 20.r);
    }

    return Icon(
      widget.icon,
      size: 20.r,
      color: _isFocused ? AppColors.primary : AppColors.textSecondary,
    );
  }

  Widget _buildSuffixIcon() {
    // If there's a tap handler, make it tappable
    Widget iconWidget;

    if (widget.suffixIconSvg != null) {
      // Use SVG icon
      iconWidget = SvgPicture.asset(
        widget.suffixIconSvg!,
        width: 20.r,
        height: 20.r,
        colorFilter: ColorFilter.mode(
          _isFocused ? AppColors.primary : AppColors.textSecondary,
          BlendMode.srcIn,
        ),
      );
    } else if (widget.suffixIcon != null) {
      // Use custom widget
      iconWidget = SizedBox(
        width: 20.r,
        height: 20.r,
        child: widget.suffixIcon,
      );
    } else if (widget.onSuffixIconTap != null && widget.obscureText) {
      // Default eye icon for password fields (temporary until SVG is added)
      iconWidget = Icon(
        Icons.visibility_off_outlined,
        size: 20.r,
        color: _isFocused ? AppColors.primary : AppColors.textSecondary,
      );
    } else if (widget.onSuffixIconTap != null && !widget.obscureText) {
      // Default eye icon for visible password
      iconWidget = Icon(
        Icons.visibility_outlined,
        size: 20.r,
        color: _isFocused ? AppColors.primary : AppColors.textSecondary,
      );
    } else {
      // Fallback to empty container
      iconWidget = const SizedBox.shrink();
    }

    // Wrap in GestureDetector if there's a tap handler
    if (widget.onSuffixIconTap != null) {
      return GestureDetector(onTap: widget.onSuffixIconTap, child: iconWidget);
    }

    return iconWidget;
  }
}
