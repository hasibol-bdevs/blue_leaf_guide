// lib/app/widgets/gradient_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../../app/utils/sizes.dart';

class Button extends StatefulWidget {
  final VoidCallback? onPressed; // <-- Changed to nullable
  final bool isLoading;
  final String text;
  final IconData? icon;
  final double? height;
  final double? width;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final EdgeInsets? padding;
  final bool showIcon;
  final Color? loadingIndicatorColor;

  const Button({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.icon,
    this.height,
    this.width,
    this.backgroundColor,
    this.borderRadius,
    this.textColor,
    this.fontSize,
    this.fontWeight,
    this.padding,
    this.showIcon = true,
    this.loadingIndicatorColor,
  });

  @override
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius =
        widget.borderRadius ?? BorderRadius.circular(AppRadius.r16);

    final textColor = widget.textColor ?? AppColors.background;
    final fontSize = widget.fontSize ?? AppFontSize.s18;
    final fontWeight = widget.fontWeight ?? FontWeight.bold;
    final height = widget.height ?? 58.h;
    final width = widget.width ?? double.infinity;
    final loadingColor = widget.loadingIndicatorColor ?? AppColors.background;
    final isEnabled =
        widget.onPressed != null && !widget.isLoading; // <-- Check if enabled

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: isEnabled
            ? (_) => _controller.forward()
            : null, // <-- Only animate if enabled
        onTapUp: isEnabled
            ? (_) {
                _controller.reverse();
                widget.onPressed!(); // <-- Safe to use ! here since we checked
              }
            : null,
        onTapCancel: isEnabled ? () => _controller.reverse() : null,
        child: Container(
          width: width,
          height: height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? AppColors.primary,
            borderRadius: borderRadius,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5.w,
                      valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.text,
                        style: TextStyle(
                          color: textColor,
                          fontSize: fontSize,
                          fontWeight: fontWeight,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (widget.showIcon && widget.icon != null) ...[
                        SizedBox(width: AppSpacing.horizontalSmall),
                        Icon(
                          widget.icon,
                          color: textColor,
                          size: AppIconSize.sm,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
