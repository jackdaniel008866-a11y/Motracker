// Motracker — Recurring Transaction Provider

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart' as app;
import '../services/database_service.dart';
import '../services/sheets_service.dart';
import 'transaction_provider.dart';

class RecurringTransactionProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final SheetsService _sheets = SheetsService();
  final _uuid = const Uuid();

  List<RecurringTransaction> _recurringTransactions = [];
  bool _isLoading = false;

  List<RecurringTransaction> get recurringTransactions => _recurringTransactions;
  bool get isLoading => _isLoading;

  List<RecurringTransaction> get activeRecurringExpenses {
    return _recurringTransactions.where((rt) => rt.isActive && rt.type == 'expense').toList();
  }

  double get monthlyRecurringCost {
    return activeRecurringExpenses.fold(0.0, (sum, rt) {
      // Normalize cost to monthly roughly
      double cost = rt.amount;
      switch (rt.frequency) {
        case 'daily':
          cost *= 30;
          break;
        case 'weekly':
          cost *= 4.33;
          break;
        case 'yearly':
          cost /= 12;
          break;
      }
      return sum + cost;
    });
  }

  Future<void> loadRecurringTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _recurringTransactions = await _db.getAllRecurringTransactions();
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addRecurringTransaction({
    required double amount,
    required String type,
    required String category,
    required String note,
    required String frequency,
    required DateTime startDate,
    String? email,
  }) async {
    final rt = RecurringTransaction(
      id: _uuid.v4(),
      amount: amount,
      type: type,
      category: category,
      note: note,
      frequency: frequency,
      startDate: startDate,
    );

    await _db.insertRecurringTransaction(rt);
    _recurringTransactions.add(rt);

    if (email != null) {
      // Assuming Google Sheets doesn't have a recurring transactions tab yet, 
      // but if it does we would sync here.
      // _sheets.addRecurringTransaction(rt, email);
    }

    notifyListeners();
  }

  Future<void> toggleActive(String id, bool isActive) async {
    final index = _recurringTransactions.indexWhere((rt) => rt.id == id);
    if (index == -1) return;

    final updated = _recurringTransactions[index].copyWith(isActive: isActive, isSynced: false);
    await _db.updateRecurringTransaction(updated);
    _recurringTransactions[index] = updated;
    notifyListeners();
  }

  Future<void> deleteRecurringTransaction(String id) async {
    await _db.deleteRecurringTransaction(id);
    _recurringTransactions.removeWhere((rt) => rt.id == id);
    notifyListeners();
  }

  /// Engine to auto-generate due transactions.
  /// This should be called on startup.
  /// Safety: Only looks back up to 90 days, and caps at 50 transactions per rule.
  Future<void> evaluateRecurringTransactions(TransactionProvider txProvider, String? email) async {
    final now = DateTime.now();
    // Safety: never look back more than 90 days to avoid flooding the DB
    final maxLookback = now.subtract(const Duration(days: 90));

    for (var rt in _recurringTransactions) {
      if (!rt.isActive) continue;

      // Start from whichever is later: the rule's startDate or maxLookback
      DateTime nextDate = rt.startDate.isBefore(maxLookback) ? maxLookback : rt.startDate;
      int generated = 0;
      const maxPerRule = 50;

      while ((nextDate.isBefore(now) || nextDate.isAtSameMomentAs(now)) && generated < maxPerRule) {
        // Only generate if this date matches the frequency pattern
        if (rt.shouldGenerateFor(nextDate)) {
          final exists = txProvider.transactions.any((t) => 
            t.category == rt.category && 
            t.amount == rt.amount && 
            t.date.year == nextDate.year && 
            t.date.month == nextDate.month && 
            t.date.day == nextDate.day
          );

          if (!exists) {
            await txProvider.addTransaction(
              amount: rt.amount,
              type: rt.type,
              category: rt.category,
              note: rt.note,
              date: nextDate,
              email: email,
            );
            generated++;
          }
        }

        // Always advance by 1 day to iterate safely
        nextDate = nextDate.add(const Duration(days: 1));
      }
    }
  }
}
