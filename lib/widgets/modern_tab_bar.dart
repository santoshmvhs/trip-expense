import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme/app_theme.dart';

/// Modern, stylish tab bar for top navigation
class ModernTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController? controller;
  final List<Tab> tabs;
  final bool isScrollable;
  final EdgeInsetsGeometry? padding;

  const ModernTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.isScrollable = false,
    this.padding,
  });

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget tabBar = Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: MomentraColors.divider.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 52,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TabBar(
            controller: controller,
            tabs: tabs,
            isScrollable: isScrollable,
            indicator: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MomentraColors.warmOrange.withValues(alpha: 0.2),
                  MomentraColors.warmOrange.withValues(alpha: 0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: MomentraColors.warmOrange.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: MomentraColors.warmOrange,
            unselectedLabelColor: MomentraColors.lightGray.withValues(alpha: 0.6),
            labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            dividerColor: Colors.transparent,
          ),
        ),
      ),
    );

    // Add glass effect on mobile (not web for performance)
    if (!kIsWeb) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: tabBar,
        ),
      );
    }

    return tabBar;
  }
}

