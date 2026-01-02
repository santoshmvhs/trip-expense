import 'package:flutter/material.dart';

/// Premium button with scale animation on tap
class PremiumAnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Duration duration;
  final double scale;

  const PremiumAnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.duration = const Duration(milliseconds: 150),
    this.scale = 0.95,
  });

  @override
  State<PremiumAnimatedButton> createState() => _PremiumAnimatedButtonState();
}

class _PremiumAnimatedButtonState extends State<PremiumAnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    if (widget.onPressed != null) {
      Future.delayed(widget.duration, () {
        if (mounted) {
          widget.onPressed!();
        }
      });
    }
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Animated card with hover/press effects
class PremiumAnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double borderRadius;
  final double elevation;

  const PremiumAnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius = 16,
    this.elevation = 2,
  });

  @override
  State<PremiumAnimatedCard> createState() => _PremiumAnimatedCardState();
}

class _PremiumAnimatedCardState extends State<PremiumAnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.elevation * 1.5,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    if (widget.onTap != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          widget.onTap!();
        }
      });
    }
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? _handleTapDown : null,
      onTapUp: widget.onTap != null ? _handleTapUp : null,
      onTapCancel: widget.onTap != null ? _handleTapCancel : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Card(
              margin: widget.margin,
              elevation: _elevationAnimation.value,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
              color: widget.backgroundColor,
              child: Padding(
                padding: widget.padding ?? EdgeInsets.zero,
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

