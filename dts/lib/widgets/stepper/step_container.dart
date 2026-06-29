import 'package:flutter/material.dart';

class StepContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final double? margin;

  const StepContainer({
    super.key,
    required this.child,
    this.padding,
    this.elevation,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(margin ?? 16.0),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: elevation ?? 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(20.0),
          child: child,
        ),
      ),
    );
  }
}
