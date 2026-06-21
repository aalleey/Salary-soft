import 'dart:ui';
import 'package:flutter/material.dart';

/// A glassmorphism container using [BackdropFilter].
/// Wrap this around any content to give it the glass-card look.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double backgroundOpacity;
  final double borderOpacity;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? tint;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 20,
    this.backgroundOpacity = 0.08,
    this.borderOpacity = 0.15,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(20),
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (tint ?? Colors.white).withValues(alpha: backgroundOpacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: borderOpacity),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
