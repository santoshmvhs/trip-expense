import 'package:flutter_test/flutter_test.dart';
import 'package:momentra/features/moments/data/models/moment.dart';
import 'package:momentra/features/moments/data/models/health.dart';

void main() {
  group('Moment Model', () {
    test('parses JSON correctly', () {
      final json = {
        '_id': '123',
        'type': 'trip',
        'title': 'Test Trip',
        'description': 'A test trip',
        'targetAmount': 1000.0,
        'currentAmount': 500.0,
        'startDate': '2024-01-01T00:00:00Z',
        'endDate': '2024-12-31T00:00:00Z',
        'lifecycleState': 'ACTIVE',
        'createdBy': 'user123',
        'createdAt': '2024-01-01T00:00:00Z',
        'updatedAt': '2024-01-01T00:00:00Z',
        'funded': false,
        'overdue': false,
        'participants': [],
      };
      
      final moment = Moment.fromJson(json);
      
      expect(moment.id, '123');
      expect(moment.type, 'trip');
      expect(moment.title, 'Test Trip');
      expect(moment.targetAmount, 1000.0);
      expect(moment.currentAmount, 500.0);
      expect(moment.progressPercentage, 50.0);
    });
  });
  
  group('HealthStatus Model', () {
    test('parses JSON correctly', () {
      final json = {
        'status': 'green',
        'label': 'on-track',
        'gap': 0.05,
        'fundingRatio': 0.5,
        'expectedFundingRatio': 0.55,
      };
      
      final health = HealthStatus.fromJson(json);
      
      expect(health.status, 'green');
      expect(health.label, 'on-track');
      expect(health.gap, 0.05);
      expect(health.fundingRatio, 0.5);
      expect(health.expectedFundingRatio, 0.55);
    });
  });
}

