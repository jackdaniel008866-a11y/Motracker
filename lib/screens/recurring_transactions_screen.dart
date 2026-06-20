import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../providers/recurring_transaction_provider.dart';
import '../models/category.dart' as app_cat;
import '../utils/formatters.dart';
import 'add_recurring_sheet.dart';

class RecurringTransactionsScreen extends StatelessWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RecurringTransactionProvider>(
      builder: (context, provider, child) {
        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Automations',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.accent),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const AddRecurringSheet(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Subscription Dashboard
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryDark, AppTheme.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.subscriptions_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Active Recurring Cost',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${Formatters.currencyCompact(provider.monthlyRecurringCost)} / mo',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ).animate().slideY(begin: 0.1, end: 0, duration: 400.ms).fadeIn(),
              ),

              // List of Recurring Transactions
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                    : provider.recurringTransactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.autorenew_rounded,
                                  size: 64,
                                  color: AppTheme.textMuted.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No recurring transactions',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn()
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: provider.recurringTransactions.length,
                            itemBuilder: (context, index) {
                              final rt = provider.recurringTransactions[index];
                              final isIncome = rt.type == 'income';
                              final color = isIncome ? AppTheme.income : AppTheme.textPrimary;
                              final categoryIcon = app_cat.AppCategories.getIcon(rt.category, rt.type);

                              return Dismissible(
                                key: Key(rt.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.expense,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(Icons.delete_rounded, color: Colors.white),
                                ),
                                confirmDismiss: (direction) async {
                                  return await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Recurring'),
                                      content: Text('Remove the recurring ${rt.category} transaction?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Delete', style: TextStyle(color: AppTheme.expense)),
                                        ),
                                      ],
                                    ),
                                  ) ?? false;
                                },
                                onDismissed: (direction) {
                                  provider.deleteRecurringTransaction(rt.id);
                                },
                                child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardDark,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: rt.isActive ? AppTheme.accent.withValues(alpha: 0.3) : Colors.transparent,
                                    width: 1,
                                  ),
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
                                        color: rt.isActive ? AppTheme.accent : AppTheme.textMuted,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            rt.category,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: rt.isActive ? AppTheme.textPrimary : AppTheme.textMuted,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${rt.frequency.toUpperCase()} • ${rt.note.isNotEmpty ? rt.note : 'No note'}',
                                            style: Theme.of(context).textTheme.bodySmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${isIncome ? '+' : '-'}${Formatters.currencyCompact(rt.amount)}',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: rt.isActive ? color : AppTheme.textMuted,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Switch(
                                          value: rt.isActive,
                                          onChanged: (val) {
                                            provider.toggleActive(rt.id, val);
                                          },
                                          activeColor: AppTheme.accent,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              ).animate().slideX(begin: 0.1, end: 0, delay: (index * 50).ms).fadeIn();
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
