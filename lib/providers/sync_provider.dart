// Motracker — Sync Provider

import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/sheets_service.dart';
import '../services/sync_service.dart';

class SyncProvider with ChangeNotifier {
  final SyncService _syncService;
  
  bool _isSyncing = false;
  String? _lastSyncMessage;
  DateTime? _lastSyncTime;
  
  bool get isSyncing => _isSyncing;
  String? get lastSyncMessage => _lastSyncMessage;
  DateTime? get lastSyncTime => _lastSyncTime;

  SyncProvider(DatabaseService db, SheetsService sheets)
      : _syncService = SyncService(db, sheets) {
    _loadLastSyncTime();
  }

  Future<void> _loadLastSyncTime() async {
    _lastSyncTime = await _syncService.getLastSyncTime();
    notifyListeners();
  }

  /// Perform a full bidirectional sync
  Future<bool> syncNow(String? email) async {
    if (email == null || _isSyncing) return false;
    
    _isSyncing = true;
    _lastSyncMessage = 'Syncing...';
    notifyListeners();
    
    try {
      final result = await _syncService.fullSync(email);
      _lastSyncMessage = result.message;
      _lastSyncTime = await _syncService.getLastSyncTime();
      
      _isSyncing = false;
      notifyListeners();
      return result.success;
    } catch (e) {
      _lastSyncMessage = 'Sync failed: $e';
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Perform initial sync when a user logs in on a fresh install
  Future<bool> initialRestoreSync(String email) async {
    if (_isSyncing) return false;
    
    _isSyncing = true;
    _lastSyncMessage = 'Restoring data from cloud...';
    notifyListeners();
    
    try {
      // For initial restore, we just pull everything
      final result = await _syncService.pullFromCloud(email);
      _lastSyncMessage = result.success 
          ? 'Successfully restored data' 
          : 'Failed to restore: ${result.error}';
      _lastSyncTime = await _syncService.getLastSyncTime();
      
      _isSyncing = false;
      notifyListeners();
      return result.success;
    } catch (e) {
      _lastSyncMessage = 'Restore failed: $e';
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }
}
