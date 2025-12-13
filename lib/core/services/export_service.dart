import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/expense.dart';
import '../models/group.dart';

class ExportService {
  /// Export expenses to PDF
  static Future<void> exportToPdf({
    required Group group,
    required List<Expense> expenses,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Expense Report: ${group.name}',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Generated on: ${DateFormat('MMMM d, y').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 30),
          
          // Summary
          pw.Header(
            level: 1,
            child: pw.Text('Summary'),
          ),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Total Expenses', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      _formatCurrency(
                        expenses.fold(0.0, (sum, e) => sum + e.amount),
                        group.currency,
                      ),
                    ),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Number of Expenses', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${expenses.length}'),
                  ),
                ],
              ),
            ],
          ),
          
          pw.SizedBox(height: 30),
          
          // Expenses
          pw.Header(
            level: 1,
            child: pw.Text('Expenses'),
          ),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildTableCell('Title', isHeader: true),
                  _buildTableCell('Amount', isHeader: true),
                  _buildTableCell('Date', isHeader: true),
                  _buildTableCell('Category', isHeader: true),
                ],
              ),
              ...expenses.map((expense) => pw.TableRow(
                children: [
                  _buildTableCell(expense.title),
                  _buildTableCell(_formatCurrency(expense.amount, expense.currency)),
                  _buildTableCell(DateFormat('MMM d, y').format(expense.expenseDate)),
                  _buildTableCell(expense.category ?? '-'),
                ],
              )),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  /// Export expenses to CSV
  static Future<void> exportToCsv({
    required Group group,
    required List<Expense> expenses,
    Map<String, String>? memberNamesMap,
  }) async {
    try {
      final buffer = StringBuffer();
      
      // Header
      buffer.writeln('Date,Title,Amount,Currency,Category,Subcategory,Paid By,Notes');
      
      // Data rows
      for (var expense in expenses) {
        final date = DateFormat('yyyy-MM-dd').format(expense.expenseDate);
        final title = _escapeCsvField(expense.title);
        final amount = expense.amount.toStringAsFixed(2);
        final currency = expense.currency;
        final category = _escapeCsvField(expense.category ?? '');
        final subcategory = _escapeCsvField(expense.subcategory ?? '');
        final paidByName = memberNamesMap?[expense.paidBy] ?? expense.paidBy.substring(0, 8);
        final paidBy = _escapeCsvField(paidByName);
        final notes = _escapeCsvField(expense.notes ?? '');
        
        buffer.writeln('$date,$title,$amount,$currency,$category,$subcategory,$paidBy,$notes');
      }
      
      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/expenses_${group.id}_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(buffer.toString());
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Expense Report - ${group.name}',
        text: 'Expense report exported from SettleLite',
      );
    } catch (e) {
      rethrow;
    }
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: isHeader
            ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
            : null,
      ),
    );
  }

  static String _formatCurrency(double amount, String currency) {
    return NumberFormat.currency(symbol: _getCurrencySymbol(currency))
        .format(amount);
  }

  static String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      case 'JPY':
        return '¥';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      default:
        return currency;
    }
  }

  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}

