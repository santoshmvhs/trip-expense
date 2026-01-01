import 'package:flutter/material.dart';

/// Momentra logo widget for AppBar
/// Displays the logo image centered in the app bar
class MomentraLogoAppBar extends StatelessWidget {
  final double height;
  
  const MomentraLogoAppBar({
    super.key,
    this.height = 250, // Increased from 32 to 48 for better visibility
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/momentra.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to text if image not found
        return const Text(
          'MOMENTRA',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        );
      },
    );
  }
}

