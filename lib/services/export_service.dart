// Motracker — CSV Export Service

import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart' as app;
import '../config/constants.dart';

class ExportService {
  /// Generate CSV string from transactions
  static Future<String> getCSVString(List<app.Transaction> transactions) async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    // Create CSV data
    final List<List<dynamic>> rows = [
      // Header row
      ['Date', 'Type', 'Category', 'Amount (${AppConstants.currencySymbol})', 'Note'],
      // Data rows
      ...transactions.map((t) => [
        dateFormat.format(t.date),
        t.type == 'income' ? 'Income' : 'Expense',
        t.category,
        t.type == 'income' ? t.amount : -t.amount,
        t.note,
      ]),
    ];

    // Calculate totals
    final totalIncome = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    rows.add([]);
    rows.add(['', 'Total Income', '', totalIncome, '']);
    rows.add(['', 'Total Expense', '', -totalExpense, '']);
    rows.add(['', 'Balance', '', totalIncome - totalExpense, '']);

    // Convert to CSV string
    return const ListToCsvConverter().convert(rows);
  }

  /// Export and share via system share sheet or download on web
  static Future<void> exportAndShare(List<app.Transaction> transactions) async {
    final csvString = await getCSVString(transactions);
    final bytes = Uint8List.fromList(utf8.encode(csvString));
    
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'motracker_export_$timestamp.csv';

    await Share.shareXFiles(
      [XFile.fromData(bytes, mimeType: 'text/csv', name: fileName)],
      subject: 'Motracker Export',
      text: 'Motracker — Transaction Export',
    );
  }
}
