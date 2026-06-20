// Motracker — Google Sheets API Service

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/transaction.dart' as app;
import '../models/budget.dart';
import '../models/recurring_transaction.dart';

class SheetsService {
  static const String _baseUrl = AppConstants.sheetsApiUrl;

  // ============================================
  // Transactions
  // ============================================

  Future<List<app.Transaction>> fetchTransactions(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=getTransactions&email=$email'),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => app.Transaction.fromJson(json as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to fetch transactions: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error fetching transactions: $e');
    }
  }

  Future<bool> addTransaction(app.Transaction transaction, String email) async {
    try {
      final encodedData = Uri.encodeComponent(jsonEncode(transaction.toJson()));
      final response = await http.get(
        Uri.parse('$_baseUrl?action=addTransaction&email=$email&data=$encodedData'),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateTransaction(app.Transaction transaction, String email) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'updateTransaction',
          'email': email,
          'data': transaction.toJson(),
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteTransaction(String id, String email) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'deleteTransaction',
          'email': email,
          'id': id,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ============================================
  // Budgets
  // ============================================

  Future<List<Budget>> fetchBudgets(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=getBudgets&email=$email'),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Budget.fromJson(json as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to fetch budgets: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error fetching budgets: $e');
    }
  }

  Future<bool> addBudget(Budget budget, String email) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'addBudget',
          'email': email,
          'data': budget.toJson(),
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteBudget(String id, String email) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'deleteBudget',
          'email': email,
          'id': id,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ============================================
  // Recurring Transactions
  // ============================================

  Future<List<RecurringTransaction>> fetchRecurring(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=getRecurring&email=$email'),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => RecurringTransaction.fromJson(json as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to fetch recurring: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error fetching recurring: $e');
    }
  }

  Future<bool> addRecurring(RecurringTransaction recurring, String email) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'addRecurring',
          'email': email,
          'data': recurring.toJson(),
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteRecurring(String id, String email) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'deleteRecurring',
          'email': email,
          'id': id,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ============================================
  // Bulk Sync
  // ============================================

  Future<Map<String, dynamic>?> syncAll({
    required String email,
    required List<app.Transaction> transactions,
    required List<Budget> budgets,
    required List<RecurringTransaction> recurring,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'syncAll',
          'email': email,
          'data': {
            'transactions': transactions.map((t) => t.toJson()).toList(),
            'budgets': budgets.map((b) => b.toJson()).toList(),
            'recurring': recurring.map((r) => r.toJson()).toList(),
          },
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // Fetch All Data
  // ============================================

  Future<Map<String, dynamic>?> fetchAll(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=getAll&email=$email'),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
