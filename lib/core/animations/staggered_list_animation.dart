import 'package:flutter/material.dart';

/// Staggered animation for list items
class StaggeredListAnimation extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final Curve curve;

  const StaggeredListAnimation({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + (delay * index),
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.9 + (0.1 * value),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// Fade in animation for list items
class FadeInListAnimation extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;

  const FadeInListAnimation({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 30),
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + (delay * index),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.95 + (0.05 * value),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

