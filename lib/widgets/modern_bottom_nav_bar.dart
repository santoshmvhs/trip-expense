import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme/app_theme.dart';

/// Modern, stylish bottom navigation bar with glass effect
class ModernBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const ModernBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget navBar = Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: MomentraColors.divider.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.groups_rounded,
                label: 'Groups',
                index: 0,
                isSelected: selectedIndex == 0,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.settings_rounded,
                label: 'Settings',
                index: 1,
                isSelected: selectedIndex == 1,
              ),
            ],
          ),
        ),
      ),
    );

    // Add glass effect on mobile (not web for performance)
    if (!kIsWeb) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: navBar,
        ),
      );
    }

    return navBar;
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    final selectedColor = MomentraColors.warmOrange;
    final unselectedColor = MomentraColors.lightGray.withValues(alpha: 0.6);
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        selectedColor.withValues(alpha: 0.2),
                        selectedColor.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : null,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(
                      color: selectedColor.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    padding: EdgeInsets.all(isSelected ? 8 : 6),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                selectedColor.withValues(alpha: 0.25),
                                selectedColor.withValues(alpha: 0.15),
                              ],
                            )
                          : null,
                      color: !isSelected ? Colors.transparent : null,
                      shape: BoxShape.circle,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: selectedColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? selectedColor : unselectedColor,
                      size: isSelected ? 24 : 22,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    style: TextStyle(
                      color: isSelected ? selectedColor : unselectedColor,
                      fontSize: isSelected ? 12 : 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: isSelected ? 0.5 : 0.3,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    height: 2.5,
                    width: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          selectedColor,
                          selectedColor.withValues(alpha: 0.8),
                          selectedColor.withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: selectedColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

