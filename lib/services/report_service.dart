import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../models/group_model.dart';
import '../models/balance_model.dart';

class ReportService {
  static Future<void> generateExpenseReport({
    required GroupModel group,
    required List<ExpenseModel> expenses,
    required List<BalanceModel> balances,
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
                  _buildTableCell('Description', isHeader: true),
                  _buildTableCell('Amount', isHeader: true),
                  _buildTableCell('Date', isHeader: true),
                  _buildTableCell('Category', isHeader: true),
                ],
              ),
              ...expenses.map((expense) => pw.TableRow(
                children: [
                  _buildTableCell(expense.description),
                  _buildTableCell(_formatCurrency(expense.amount, expense.currency)),
                  _buildTableCell(DateFormat('MMM d, y').format(expense.createdAt)),
                  _buildTableCell(expense.category ?? '-'),
                ],
              )),
            ],
          ),
          
          pw.SizedBox(height: 30),
          
          // Balances
          if (balances.isNotEmpty) ...[
            pw.Header(
              level: 1,
              child: pw.Text('Current Balances'),
            ),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildTableCell('Person', isHeader: true),
                    _buildTableCell('Balance', isHeader: true),
                  ],
                ),
                ...balances.map((balance) => pw.TableRow(
                  children: [
                    _buildTableCell(balance.userName),
                    _buildTableCell(
                      balance.isOwed
                          ? 'Gets back ${_formatCurrency(balance.absoluteBalance, group.currency)}'
                          : 'Owes ${_formatCurrency(balance.absoluteBalance, group.currency)}',
                    ),
                  ],
                )),
              ],
            ),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
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
      default:
        return currency;
    }
  }
}

