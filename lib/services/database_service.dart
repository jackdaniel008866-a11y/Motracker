// Motracker — SQLite Database Service

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/transaction.dart' as app;
import '../models/budget.dart';
import '../models/recurring_transaction.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<void> reset() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> _initDB() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString(AppConstants.prefUserEmail) ?? 'guest';
    final sanitizedEmail = userEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final dbName = 'motracker_$sanitizedEmail.db';

    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await openDatabase(
        dbName,
        version: AppConstants.dbVersion,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    } else {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, dbName);
      return await openDatabase(
        path,
        version: AppConstants.dbVersion,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE custom_categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          iconCodePoint INTEGER NOT NULL,
          iconFontFamily TEXT,
          colorHex INTEGER NOT NULL,
          type TEXT NOT NULL,
          isSynced INTEGER DEFAULT 0
        )
      ''');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        note TEXT DEFAULT '',
        date TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isSynced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        budgetLimit REAL NOT NULL,
        month TEXT NOT NULL,
        isSynced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE recurring_transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        note TEXT DEFAULT '',
        frequency TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT,
        isActive INTEGER DEFAULT 1,
        isSynced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        iconCodePoint INTEGER NOT NULL,
        iconFontFamily TEXT,
        colorHex INTEGER NOT NULL,
        type TEXT NOT NULL,
        isSynced INTEGER DEFAULT 0
      )
    ''');

    // Create indexes for common queries
    await db.execute('CREATE INDEX idx_transactions_date ON transactions(date)');
    await db.execute('CREATE INDEX idx_transactions_type ON transactions(type)');
    await db.execute('CREATE INDEX idx_transactions_category ON transactions(category)');
    await db.execute('CREATE INDEX idx_budgets_month ON budgets(month)');
  }

  // ============================================
  // Transaction CRUD
  // ============================================

  Future<void> insertTransaction(app.Transaction transaction) async {
    final db = await database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTransaction(app.Transaction transaction) async {
    final db = await database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<app.Transaction>> getAllTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC, createdAt DESC');
    return maps.map((map) => app.Transaction.fromMap(map)).toList();
  }

  Future<List<app.Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC, createdAt DESC',
    );
    return maps.map((map) => app.Transaction.fromMap(map)).toList();
  }

  Future<List<app.Transaction>> getTransactionsByMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return getTransactionsByDateRange(start, end);
  }

  Future<List<app.Transaction>> getTransactionsByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );
    return maps.map((map) => app.Transaction.fromMap(map)).toList();
  }

  Future<List<app.Transaction>> getUnsyncedTransactions() async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'isSynced = 0',
    );
    return maps.map((map) => app.Transaction.fromMap(map)).toList();
  }

  Future<void> markTransactionSynced(String id) async {
    final db = await database;
    await db.update(
      'transactions',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<app.Transaction>> searchTransactions(String query) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'note LIKE ? OR category LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'date DESC',
    );
    return maps.map((map) => app.Transaction.fromMap(map)).toList();
  }

  // ============================================
  // Monthly Aggregations
  // ============================================

  Future<double> getMonthlyTotal(int year, int month, String type) async {
    final db = await database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = ? AND date >= ? AND date <= ?',
      [type, start, end],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, double>> getCategoryTotals(int year, int month, String type) async {
    final db = await database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      'SELECT category, SUM(amount) as total FROM transactions WHERE type = ? AND date >= ? AND date <= ? GROUP BY category ORDER BY total DESC',
      [type, start, end],
    );

    final Map<String, double> totals = {};
    for (final row in result) {
      totals[row['category'] as String] = (row['total'] as num).toDouble();
    }
    return totals;
  }

  // ============================================
  // Budget CRUD
  // ============================================

  Future<void> insertBudget(Budget budget) async {
    final db = await database;
    await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateBudget(Budget budget) async {
    final db = await database;
    await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<void> deleteBudget(String id) async {
    final db = await database;
    await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Budget>> getBudgetsByMonth(String month) async {
    final db = await database;
    final maps = await db.query(
      'budgets',
      where: 'month = ?',
      whereArgs: [month],
    );
    return maps.map((map) => Budget.fromMap(map)).toList();
  }

  Future<List<Budget>> getAllBudgets() async {
    final db = await database;
    final maps = await db.query('budgets', orderBy: 'month DESC');
    return maps.map((map) => Budget.fromMap(map)).toList();
  }

  Future<List<Budget>> getUnsyncedBudgets() async {
    final db = await database;
    final maps = await db.query('budgets', where: 'isSynced = 0');
    return maps.map((map) => Budget.fromMap(map)).toList();
  }

  Future<void> markBudgetSynced(String id) async {
    final db = await database;
    await db.update('budgets', {'isSynced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // ============================================
  // Recurring Transaction CRUD
  // ============================================

  Future<void> insertRecurringTransaction(RecurringTransaction recurring) async {
    final db = await database;
    await db.insert(
      'recurring_transactions',
      recurring.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateRecurringTransaction(RecurringTransaction recurring) async {
    final db = await database;
    await db.update(
      'recurring_transactions',
      recurring.toMap(),
      where: 'id = ?',
      whereArgs: [recurring.id],
    );
  }

  Future<void> deleteRecurringTransaction(String id) async {
    final db = await database;
    await db.delete(
      'recurring_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<RecurringTransaction>> getActiveRecurringTransactions() async {
    final db = await database;
    final maps = await db.query(
      'recurring_transactions',
      where: 'isActive = 1',
    );
    return maps.map((map) => RecurringTransaction.fromMap(map)).toList();
  }

  Future<List<RecurringTransaction>> getAllRecurringTransactions() async {
    final db = await database;
    final maps = await db.query('recurring_transactions');
    return maps.map((map) => RecurringTransaction.fromMap(map)).toList();
  }

  Future<List<RecurringTransaction>> getUnsyncedRecurringTransactions() async {
    final db = await database;
    final maps = await db.query('recurring_transactions', where: 'isSynced = 0');
    return maps.map((map) => RecurringTransaction.fromMap(map)).toList();
  }

  Future<void> markRecurringSynced(String id) async {
    final db = await database;
    await db.update('recurring_transactions', {'isSynced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // ============================================
  // ============================================
  // Custom Categories
  // ============================================

  Future<void> insertCustomCategory(Map<String, dynamic> categoryMap) async {
    final db = await database;
    await db.insert(
      'custom_categories',
      categoryMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getCustomCategories() async {
    final db = await database;
    return await db.query('custom_categories');
  }

  // ============================================
  // Utility
  // ============================================

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('budgets');
    await db.delete('recurring_transactions');
    await db.delete('custom_categories');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
