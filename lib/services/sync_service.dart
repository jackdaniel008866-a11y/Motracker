// Motracker — Sync Service (Local ↔ Cloud)

import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/transaction.dart' as app;
import '../models/budget.dart';
import '../models/recurring_transaction.dart';
import 'database_service.dart';
import 'sheets_service.dart';

class SyncService {
  final DatabaseService _db;
  final SheetsService _sheets;

  SyncService(this._db, this._sheets);

  /// Push all unsynced local data to Google Sheets
  Future<SyncResult> pushToCloud(String email) async {
    int pushed = 0;
    int failed = 0;

    try {
      // Push unsynced transactions
      final unsyncedTransactions = await _db.getUnsyncedTransactions();
      for (final t in unsyncedTransactions) {
        final success = await _sheets.addTransaction(t, email);
        if (success) {
          await _db.markTransactionSynced(t.id);
          pushed++;
        } else {
          failed++;
        }
      }

      // Push unsynced budgets
      final unsyncedBudgets = await _db.getUnsyncedBudgets();
      for (final b in unsyncedBudgets) {
        final success = await _sheets.addBudget(b, email);
        if (success) {
          await _db.markBudgetSynced(b.id);
          pushed++;
        } else {
          failed++;
        }
      }

      // Push unsynced recurring
      final unsyncedRecurring = await _db.getUnsyncedRecurringTransactions();
      for (final r in unsyncedRecurring) {
        final success = await _sheets.addRecurring(r, email);
        if (success) {
          await _db.markRecurringSynced(r.id);
          pushed++;
        } else {
          failed++;
        }
      }

      await _updateLastSyncTime();

      return SyncResult(
        success: true,
        pushed: pushed,
        pulled: 0,
        failed: failed,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        pushed: pushed,
        pulled: 0,
        failed: failed,
        error: e.toString(),
      );
    }
  }

  /// Pull all data from Google Sheets and merge into local DB
  Future<SyncResult> pullFromCloud(String email) async {
    int pulled = 0;

    try {
      final cloudData = await _sheets.fetchAll(email);
      if (cloudData == null) {
        return SyncResult(success: false, error: 'Failed to fetch cloud data');
      }

      // Merge transactions
      if (cloudData['transactions'] is List) {
        final cloudTransactions = (cloudData['transactions'] as List)
            .map((json) => app.Transaction.fromJson(json as Map<String, dynamic>))
            .toList();

        final localTransactions = await _db.getAllTransactions();
        final localIds = localTransactions.map((t) => t.id).toSet();
        final cloudIds = cloudTransactions.map((t) => t.id).toSet();

        for (final t in localTransactions) {
          if (t.isSynced && !cloudIds.contains(t.id)) {
            await _db.deleteTransaction(t.id);
            pulled++;
          }
        }

        for (final t in cloudTransactions) {
          if (!localIds.contains(t.id)) {
            await _db.insertTransaction(t.copyWith(isSynced: true));
            pulled++;
          }
        }
      }

      // Merge budgets
      if (cloudData['budgets'] is List) {
        final cloudBudgets = (cloudData['budgets'] as List)
            .map((json) => Budget.fromJson(json as Map<String, dynamic>))
            .toList();

        final localBudgets = await _db.getAllBudgets();
        final localIds = localBudgets.map((b) => b.id).toSet();
        final cloudIds = cloudBudgets.map((b) => b.id).toSet();

        for (final b in localBudgets) {
          if (b.isSynced && !cloudIds.contains(b.id)) {
            await _db.deleteBudget(b.id);
            pulled++;
          }
        }

        for (final b in cloudBudgets) {
          if (!localIds.contains(b.id)) {
            await _db.insertBudget(b.copyWith(isSynced: true));
            pulled++;
          }
        }
      }

      // Merge recurring
      if (cloudData['recurring'] is List) {
        final cloudRecurring = (cloudData['recurring'] as List)
            .map((json) => RecurringTransaction.fromJson(json as Map<String, dynamic>))
            .toList();

        final localRecurring = await _db.getAllRecurringTransactions();
        final localIds = localRecurring.map((r) => r.id).toSet();
        final cloudIds = cloudRecurring.map((r) => r.id).toSet();

        for (final r in localRecurring) {
          if (r.isSynced && !cloudIds.contains(r.id)) {
            await _db.deleteRecurringTransaction(r.id);
            pulled++;
          }
        }

        for (final r in cloudRecurring) {
          if (!localIds.contains(r.id)) {
            await _db.insertRecurringTransaction(r.copyWith(isSynced: true));
            pulled++;
          }
        }
      }

      await _updateLastSyncTime();

      return SyncResult(
        success: true,
        pushed: 0,
        pulled: pulled,
        failed: 0,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Full sync: push local changes then pull cloud changes
  Future<SyncResult> fullSync(String email) async {
    final pushResult = await pushToCloud(email);
    final pullResult = await pullFromCloud(email);

    return SyncResult(
      success: pushResult.success && pullResult.success,
      pushed: pushResult.pushed,
      pulled: pullResult.pulled,
      failed: pushResult.failed + pullResult.failed,
      error: pushResult.error ?? pullResult.error,
    );
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString(AppConstants.prefLastSyncTime);
    if (timeStr != null) {
      return DateTime.tryParse(timeStr);
    }
    return null;
  }

  Future<void> _updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.prefLastSyncTime,
      DateTime.now().toIso8601String(),
    );
  }
}

class SyncResult {
  final bool success;
  final int pushed;
  final int pulled;
  final int failed;
  final String? error;

  SyncResult({
    this.success = false,
    this.pushed = 0,
    this.pulled = 0,
    this.failed = 0,
    this.error,
  });

  String get message {
    if (!success) return 'Sync failed: ${error ?? "Unknown error"}';
    if (pushed == 0 && pulled == 0) return 'Already up to date';
    final parts = <String>[];
    if (pushed > 0) parts.add('$pushed pushed');
    if (pulled > 0) parts.add('$pulled pulled');
    if (failed > 0) parts.add('$failed failed');
    return parts.join(', ');
  }
}
