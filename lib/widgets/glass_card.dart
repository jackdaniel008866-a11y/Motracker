import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool isAccent;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20.0,
    this.isAccent = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: isAccent ? AppTheme.glassCardAccent : _defaultGlassDecoration(),
          child: child,
        ),
      ),
    );
  }

  BoxDecoration _defaultGlassDecoration() => BoxDecoration(
    color: AppTheme.surfaceDark.withValues(alpha: 0.6),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.05),
      width: 1,
    ),
  );
}
