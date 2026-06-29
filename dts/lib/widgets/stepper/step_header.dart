import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StepHeader extends StatelessWidget {
  final String title;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  const StepHeader({
    super.key,
    required this.title,
    this.backgroundColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: textStyle ??
            const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}
