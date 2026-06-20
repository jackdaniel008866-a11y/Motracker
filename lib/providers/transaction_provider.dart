// Motracker — Transaction Provider

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart' as app;
import '../models/category.dart';
import '../services/database_service.dart';
import '../services/sheets_service.dart';
import '../utils/formatters.dart';

enum DateFilter { thisWeek, thisMonth, thisYear, allTime }

class TransactionProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final SheetsService _sheets = SheetsService();
  final _uuid = const Uuid();

  List<app.Transaction> _transactions = [];
  List<app.Transaction> _filteredTransactions = [];
  bool _isLoading = false;
  String? _error;
  
  // Dashboard filter
  DateFilter _dateFilter = DateFilter.thisMonth;
  String _searchQuery = '';
  String? _filterCategory;
  String? _filterType;

  // Getters
  List<app.Transaction> get transactions => _filteredTransactions.isEmpty && _searchQuery.isEmpty && _filterCategory == null && _filterType == null
      ? _transactions
      : _filteredTransactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateFilter get dateFilter => _dateFilter;

  // ============================================
  // Dashboard Calculations
  // ============================================

  List<app.Transaction> get filteredStatsTransactions {
    final now = DateTime.now();
    return _transactions.where((t) {
      switch (_dateFilter) {
        case DateFilter.thisWeek:
          // Start of current week (Monday)
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          return t.date.isAfter(start) || t.date.isAtSameMomentAs(start);
        case DateFilter.thisMonth:
          return t.date.year == now.year && t.date.month == now.month;
        case DateFilter.thisYear:
          return t.date.year == now.year;
        case DateFilter.allTime:
          return true;
      }
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  List<app.Transaction> get currentMonthTransactions {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();
  }

  double get monthlyIncome {
    return filteredStatsTransactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get monthlyExpense {
    return filteredStatsTransactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get monthlyBalance => monthlyIncome - monthlyExpense;

  double get totalBalance {
    final totalIncome = _transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = _transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    return totalIncome - totalExpense;
  }

  List<app.Transaction> get recentTransactions {
    final sorted = List<app.Transaction>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(10).toList();
  }

  Map<String, double> get categoryExpenses {
    final Map<String, double> result = {};
    for (final t in filteredStatsTransactions) {
      if (t.type == 'expense') {
        result[t.category] = (result[t.category] ?? 0) + t.amount;
      }
    }
    return Map.fromEntries(
      result.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  Map<String, double> get categoryIncome {
    final Map<String, double> result = {};
    for (final t in filteredStatsTransactions) {
      if (t.type == 'income') {
        result[t.category] = (result[t.category] ?? 0) + t.amount;
      }
    }
    return Map.fromEntries(
      result.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  /// Get daily totals for chart (only relevant for week/month)
  Map<int, double> get dailyExpenses {
    final Map<int, double> result = {};
    for (final t in filteredStatsTransactions) {
      if (t.type == 'expense') {
        // Group by day of year for week, or day of month for month
        int key = _dateFilter == DateFilter.thisYear ? t.date.month : t.date.day;
        result[key] = (result[key] ?? 0) + t.amount;
      }
    }
    return result;
  }

  /// Group transactions by date for list display
  Map<String, List<app.Transaction>> get groupedTransactions {
    final Map<String, List<app.Transaction>> result = {};
    final list = _filterCategory != null || _filterType != null || _searchQuery.isNotEmpty
        ? _filteredTransactions
        : _transactions;
    
    for (final t in list) {
      final key = Formatters.relativeDate(t.date);
      result.putIfAbsent(key, () => []);
      result[key]!.add(t);
    }
    return result;
  }

  // ============================================
  // Monthly Stats for Charts
  // ============================================

  /// Get last 6 months income/expense totals
  List<MonthlyData> get last6MonthsData {
    final List<MonthlyData> data = [];
    final now = DateTime.now();
    
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final income = _transactions
          .where((t) => t.type == 'income' && t.date.year == month.year && t.date.month == month.month)
          .fold(0.0, (sum, t) => sum + t.amount);
      final expense = _transactions
          .where((t) => t.type == 'expense' && t.date.year == month.year && t.date.month == month.month)
          .fold(0.0, (sum, t) => sum + t.amount);
      
      data.add(MonthlyData(month: month, income: income, expense: expense));
    }
    
    return data;
  }

  // ============================================
  // CRUD Operations
  // ============================================

  Future<void> loadTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await _db.getAllTransactions();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTransaction({
    required double amount,
    required String type,
    required String category,
    String note = '',
    DateTime? date,
    String? email,
  }) async {
    final transaction = app.Transaction(
      id: _uuid.v4(),
      amount: amount,
      type: type,
      category: category,
      note: note,
      date: date ?? DateTime.now(),
    );

    await _db.insertTransaction(transaction);
    _transactions.insert(0, transaction);
    _applyFilters();
    notifyListeners();

    // Sync to cloud in background
    if (email != null) {
      _sheets.addTransaction(transaction, email).then((success) async {
        if (success) {
          await _db.markTransactionSynced(transaction.id);
        }
      });
    }
  }

  Future<void> updateTransaction(app.Transaction transaction, {String? email}) async {
    final updated = transaction.copyWith(isSynced: false);
    await _db.updateTransaction(updated);
    
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = updated;
    }
    _applyFilters();
    notifyListeners();

    if (email != null) {
      _sheets.updateTransaction(transaction, email).then((success) async {
        if (success) {
          await _db.markTransactionSynced(transaction.id);
        }
      });
    }
  }

  Future<void> deleteTransaction(String id, {String? email}) async {
    await _db.deleteTransaction(id);
    _transactions.removeWhere((t) => t.id == id);
    _applyFilters();
    notifyListeners();

    if (email != null) {
      _sheets.deleteTransaction(id, email);
    }
  }

  // ============================================
  // Filtering & Search
  // ============================================

  void setDateFilter(DateFilter filter) {
    _dateFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setFilterCategory(String? category) {
    _filterCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setFilterType(String? type) {
    _filterType = type;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterCategory = null;
    _filterType = null;
    _filteredTransactions = [];
    notifyListeners();
  }

  void _applyFilters() {
    if (_searchQuery.isEmpty && _filterCategory == null && _filterType == null) {
      _filteredTransactions = [];
      return;
    }

    _filteredTransactions = _transactions.where((t) {
      bool matches = true;
      if (_searchQuery.isNotEmpty) {
        matches = matches &&
            (t.note.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             t.category.toLowerCase().contains(_searchQuery.toLowerCase()));
      }
      if (_filterCategory != null) {
        matches = matches && t.category == _filterCategory;
      }
      if (_filterType != null) {
        matches = matches && t.type == _filterType;
      }
      return matches;
    }).toList();
  }
}

class MonthlyData {
  final DateTime month;
  final double income;
  final double expense;

  MonthlyData({required this.month, required this.income, required this.expense});
  
  double get balance => income - expense;
}
