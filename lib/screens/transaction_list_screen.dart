// Motracker — Transaction List Screen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/transaction.dart' as app;
import '../providers/transaction_provider.dart';
import '../utils/formatters.dart';
import '../models/category.dart' as app_cat;
import '../providers/auth_provider.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final groupedTransactions = provider.groupedTransactions;

        return SafeArea(
          child: Column(
            children: [
              // Header & Search
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Transactions',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isSearching ? Icons.close_rounded : Icons.search_rounded,
                            color: AppTheme.textPrimary,
                          ),
                          onPressed: () {
                            setState(() {
                              _isSearching = !_isSearching;
                              if (!_isSearching) {
                                _searchController.clear();
                                provider.setSearchQuery('');
                              }
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.filter_list_rounded, color: AppTheme.textPrimary),
                          onPressed: () => _showFilterSheet(context, provider),
                        ),
                      ],
                    ),
                    if (_isSearching) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) => provider.setSearchQuery(value),
                        decoration: InputDecoration(
                          hintText: 'Search notes or categories...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          filled: true,
                          fillColor: AppTheme.cardDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ).animate().slideY(begin: -0.2, end: 0, duration: 300.ms).fadeIn(),
                    ],
                    
                    // Active Filters Display
                    // We can add chips here to show active filters
                  ],
                ),
              ),

              // Transaction List
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                    : groupedTransactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_rounded,
                                  size: 64,
                                  color: AppTheme.textMuted.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No transactions found',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn()
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 100), // Space for bottom nav
                            itemCount: groupedTransactions.length,
                            itemBuilder: (context, index) {
                              final dateKey = groupedTransactions.keys.elementAt(index);
                              final transactions = groupedTransactions[dateKey]!;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                                    child: Text(
                                      dateKey,
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ).animate().fadeIn(delay: (100 + (index * 50)).ms),
                                  
                                  ...transactions.map((t) => _ListTransactionTile(transaction: t)
                                      .animate()
                                      .slideX(begin: 0.1, end: 0, delay: (200 + (index * 50)).ms)
                                      .fadeIn()),
                                ],
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context, TransactionProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Transactions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        provider.clearFilters();
                        Navigator.pop(context);
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Type',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          provider.setFilterType('income');
                          Navigator.pop(context);
                        },
                        child: const Text('Income'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          provider.setFilterType('expense');
                          Navigator.pop(context);
                        },
                        child: const Text('Expense'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ListTransactionTile extends StatelessWidget {
  final app.Transaction transaction;

  const _ListTransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final color = isIncome ? AppTheme.income : AppTheme.textPrimary;
    final categoryIcon = app_cat.AppCategories.getIcon(transaction.category, transaction.type);

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.expense,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (direction) {
        final email = context.read<AuthProvider>().userEmail;
        context.read<TransactionProvider>().deleteTransaction(transaction.id, email: email);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaction deleted')),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                categoryIcon,
                color: AppTheme.accent,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.category,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (transaction.note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      transaction.note,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${Formatters.currency(transaction.amount)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.time(transaction.date),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
