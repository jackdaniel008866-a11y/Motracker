// Motracker — Budget Provider

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/budget.dart';
import '../services/database_service.dart';
import '../services/sheets_service.dart';
import '../utils/formatters.dart';

class BudgetProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final SheetsService _sheets = SheetsService();
  final _uuid = const Uuid();

  List<Budget> _budgets = [];
  bool _isLoading = false;

  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;

  /// Get budgets for current month
  List<Budget> get currentMonthBudgets {
    final currentMonth = Formatters.monthKey(DateTime.now());
    return _budgets.where((b) => b.month == currentMonth).toList();
  }

  /// Get budget for a specific category and month
  Budget? getBudget(String category, String month) {
    try {
      return _budgets.firstWhere(
        (b) => b.category == category && b.month == month,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> loadBudgets() async {
    _isLoading = true;
    notifyListeners();

    try {
      _budgets = await _db.getAllBudgets();
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addBudget({
    required String category,
    required double limit,
    required String month,
    String? email,
  }) async {
    // Check if budget already exists for this category & month
    final existing = getBudget(category, month);
    if (existing != null) {
      // Update existing
      final updated = existing.copyWith(limit: limit, isSynced: false);
      await _db.updateBudget(updated);
      final index = _budgets.indexWhere((b) => b.id == existing.id);
      if (index != -1) _budgets[index] = updated;
    } else {
      final budget = Budget(
        id: _uuid.v4(),
        category: category,
        limit: limit,
        month: month,
      );

      await _db.insertBudget(budget);
      _budgets.add(budget);

      if (email != null) {
        _sheets.addBudget(budget, email).then((success) async {
          if (success) await _db.markBudgetSynced(budget.id);
        });
      }
    }

    notifyListeners();
  }

  Future<void> deleteBudget(String id, {String? email}) async {
    await _db.deleteBudget(id);
    _budgets.removeWhere((b) => b.id == id);
    notifyListeners();

    if (email != null) {
      _sheets.deleteBudget(id, email);
    }
  }

  /// Check budget status: returns spent/limit ratio
  double getBudgetUsage(String category, String month, double spent) {
    final budget = getBudget(category, month);
    if (budget == null || budget.limit == 0) return 0;
    return spent / budget.limit;
  }
}
