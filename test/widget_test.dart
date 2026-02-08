import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momentra/widgets/health_badge.dart';
import 'package:momentra/widgets/guidance_card.dart';
import 'package:momentra/features/moments/data/models/guidance.dart';

void main() {
  group('HealthBadge Widget', () {
    testWidgets('displays health status correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HealthBadge(status: 'green', label: 'on-track'),
          ),
        ),
      );
      
      expect(find.text('ON-TRACK'), findsOneWidget);
    });
  });
  
  group('GuidanceCard Widget', () {
    testWidgets('displays guidance nudges', (WidgetTester tester) async {
      final guidance = Guidance(
        nudges: [
          GuidanceNudge(message: 'Test nudge', priority: 'medium'),
        ],
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuidanceCard(guidance: guidance),
          ),
        ),
      );
      
      expect(find.text('Test nudge'), findsOneWidget);
      expect(find.text('Suggested Actions'), findsOneWidget);
    });
    
    testWidgets('displays empty state when no nudges', (WidgetTester tester) async {
      final guidance = Guidance(nudges: []);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuidanceCard(guidance: guidance),
          ),
        ),
      );
      
      expect(find.text('All good! No actions needed.'), findsOneWidget);
    });
  });
}
