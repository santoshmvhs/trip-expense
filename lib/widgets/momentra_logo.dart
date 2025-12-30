import 'package:flutter/material.dart';

class MomentraLogo extends StatelessWidget {
  final double? size;
  final bool showText;
  
  const MomentraLogo({
    super.key,
    this.size,
    this.showText = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/momentra.png',
          width: size ?? 120,
          height: size ?? 120,
          fit: BoxFit.contain,
        ),
        if (showText) ...[
          const SizedBox(height: 8),
          Text(
            'MOMENTRA',
            style: TextStyle(
              fontSize: (size ?? 120) * 0.15,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: Colors.white,
            ),
          ),
        ],
      ],
    );
  }
}

class MomentraLogoSmall extends StatelessWidget {
  final double size;
  
  const MomentraLogoSmall({
    super.key,
    this.size = 32,
  });
  
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/momentra.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

