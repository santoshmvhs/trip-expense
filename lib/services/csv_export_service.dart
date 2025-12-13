import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../models/group_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CsvExportService {
  static Future<void> exportToCsv({
    required GroupModel group,
    required List<ExpenseModel> expenses,
  }) async {
    try {
      final buffer = StringBuffer();
      
      // Header
      buffer.writeln('Date,Description,Amount,Currency,Category,Paid By,Recurring');
      
      // Data rows
      for (var expense in expenses) {
        final date = DateFormat('yyyy-MM-dd').format(expense.createdAt);
        final description = _escapeCsvField(expense.description);
        final amount = expense.amount.toStringAsFixed(2);
        final currency = expense.currency;
        final category = _escapeCsvField(expense.category ?? '');
        final paidBy = _escapeCsvField('User ${expense.paidBy.substring(0, 8)}');
        final recurring = expense.isRecurring ? 'Yes' : 'No';
        
        buffer.writeln('$date,$description,$amount,$currency,$category,$paidBy,$recurring');
      }
      
      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/expenses_${group.id}_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(buffer.toString());
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Expense Report - ${group.name}',
        text: 'Expense report exported from SettleUp',
      );
    } catch (e) {
      rethrow;
    }
  }

  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}

