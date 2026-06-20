// Motracker — Home Screen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../utils/formatters.dart';
import '../widgets/glass_card.dart';
import '../widgets/bouncy_card.dart';
import '../widgets/empty_state.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/sync_provider.dart';
import '../models/transaction.dart' as app;
import '../models/category.dart' as app_cat;

import 'add_transaction_screen.dart';
import 'transaction_list_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import 'add_budget_sheet.dart';
import 'recurring_transactions_screen.dart';

import '../providers/recurring_transaction_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final txProv = context.read<TransactionProvider>();
      final recurringProv = context.read<RecurringTransactionProvider>();
      final email = context.read<AuthProvider>().userEmail;

      await txProv.loadTransactions();
      context.read<BudgetProvider>().loadBudgets();
      
      await recurringProv.loadRecurringTransactions();
      await recurringProv.evaluateRecurringTransactions(txProv, email);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Basic navigation setup for bottom nav bar
    final List<Widget> pages = [
      _DashboardView(onNavigateToList: () => setState(() => _currentIndex = 1)),
      const TransactionListScreen(),
      const RecurringTransactionsScreen(),
      const StatsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: AppTheme.accent,
          foregroundColor: AppTheme.primaryDark,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
            );
          },
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ).animate().scale(delay: 500.ms, curve: Curves.easeOutBack),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppTheme.surfaceDark,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'Home'),
            _buildNavItem(1, Icons.receipt_long_rounded, 'List'),
            _buildNavItem(2, Icons.autorenew_rounded, 'Auto'),
            _buildNavItem(3, Icons.pie_chart_rounded, 'Stats'),
            _buildNavItem(4, Icons.settings_rounded, 'Settings'),
            const SizedBox(width: 40), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppTheme.accent : AppTheme.textMuted,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isSelected ? AppTheme.accent : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  final VoidCallback onNavigateToList;

  const _DashboardView({required this.onNavigateToList});

  @override
  Widget build(BuildContext context) {
    return Consumer3<TransactionProvider, AuthProvider, BudgetProvider>(
      builder: (context, provider, auth, budgetProv, _) {
        final recentTransactions = provider.recentTransactions;
        return SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.cardDarkAlt,
                        backgroundImage: auth.userPhoto != null 
                            ? NetworkImage(auth.userPhoto!) 
                            : null,
                        child: auth.userPhoto == null 
                            ? const Icon(Icons.person_rounded, color: AppTheme.textSecondary)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello,',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              auth.userName ?? 'User',
                              style: Theme.of(context).textTheme.titleLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          final email = auth.userEmail;
                          context.read<SyncProvider>().syncNow(email).then((success) {
                            if (context.mounted) {
                              final provider = context.read<SyncProvider>();
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(provider.lastSyncMessage ?? (success ? 'Sync complete!' : 'Sync failed')),
                                  backgroundColor: success ? AppTheme.accent : AppTheme.expense,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                              // Reload transactions after sync
                              context.read<TransactionProvider>().loadTransactions();
                              context.read<BudgetProvider>().loadBudgets();
                            }
                          });
                        },
                        icon: const Icon(Icons.cloud_sync_rounded, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),
              ),
              
              // Balance Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Total Balance',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Formatters.currencyWithDecimals(provider.totalBalance),
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildIncomeExpenseSummary(
                                context,
                                'Income',
                                provider.monthlyIncome,
                                Icons.arrow_downward_rounded,
                                AppTheme.income,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                            Expanded(
                              child: _buildIncomeExpenseSummary(
                                context,
                                'Expense',
                                provider.monthlyExpense,
                                Icons.arrow_upward_rounded,
                                AppTheme.expense,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: 0.1, end: 0, duration: 500.ms).fadeIn(),
                ),
              ),
              
              // Monthly Budgets Header
              if (budgetProv.currentMonthBudgets.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Monthly Budgets',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const AddBudgetSheet(),
                            );
                          },
                          icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.accent),
                        ),
                      ],
                    ).animate().fadeIn(delay: 100.ms),
                  ),
                ),
                
                // Budget List
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final budget = budgetProv.currentMonthBudgets[index];
                      // Calculate spent from current month transactions
                      final spent = provider.currentMonthTransactions
                          .where((t) => t.category == budget.category && t.type == 'expense')
                          .fold(0.0, (sum, t) => sum + t.amount);
                      
                      final usage = budgetProv.getBudgetUsage(budget.category, budget.month, spent);
                      final isOver = usage >= 1.0;
                      final isWarning = usage >= 0.9 && !isOver;
                      
                      final barColor = isOver 
                          ? AppTheme.expense 
                          : (isWarning ? Colors.orange : AppTheme.accent);

                      final categoryIcon = app_cat.AppCategories.getIcon(budget.category, 'expense');

                      return GestureDetector(
                        onLongPress: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Budget'),
                              content: Text('Remove the budget for "${budget.category}"?'),
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
                          );
                          if (confirm == true && context.mounted) {
                            final email = context.read<AuthProvider>().userEmail;
                            budgetProv.deleteBudget(budget.id, email: email);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(categoryIcon, size: 16, color: AppTheme.textSecondary),
                                      const SizedBox(width: 8),
                                      Text(
                                        budget.category,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${Formatters.currencyCompact(spent)} / ${Formatters.currencyCompact(budget.limit)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: barColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: usage > 1.0 ? 1.0 : usage,
                                  backgroundColor: AppTheme.cardDarkAlt,
                                  color: barColor,
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: (200 + (index * 50)).ms),
                        ),
                      );
                    },
                    childCount: budgetProv.currentMonthBudgets.length,
                  ),
                ),
              ],
              
              // Recent Transactions Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: onNavigateToList,
                        child: const Text('See All'),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms),
                ),
              ),
              
              // Recent Transactions List
              if (provider.isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: AppTheme.accent),
                    ),
                  ),
                )
              else if (recentTransactions.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: const EmptyStateWidget(
                      icon: Icons.receipt_long_rounded,
                      title: 'No transactions yet',
                      subtitle: 'Your recent expenses and income will appear here.',
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final t = provider.recentTransactions[index];
                      return _TransactionTile(transaction: t)
                          .animate()
                          .slideX(begin: 0.1, end: 0, delay: (300 + (index * 50)).ms)
                          .fadeIn();
                    },
                    childCount: provider.recentTransactions.length,
                  ),
                ),
                
              const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom padding
            ],
          ),
        );
      },
    );
  }

  Widget _buildIncomeExpenseSummary(
    BuildContext context, 
    String label, 
    double amount, 
    IconData icon, 
    Color color
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryDark.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          Formatters.currencyCompact(amount),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final app.Transaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == AppConstants.typeIncome;
    final color = isIncome ? AppTheme.income : AppTheme.expense;
    
    // Find icon from category
    IconData iconData = Icons.receipt_rounded;
    Color iconColor = color;
    
    final appCats = app_cat.AppCategories.getByType(transaction.type);
    try {
      final cat = appCats.firstWhere((c) => c.id == transaction.category);
      iconData = cat.icon;
      iconColor = cat.color;
    } catch (_) {}
    
    return BouncyCard(
      onTap: () => _showOptions(context),
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
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              iconData,
              color: iconColor,
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
                Formatters.dateShort(transaction.date),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.edit_rounded, color: AppTheme.accent),
                ),
                title: const Text('Edit Transaction', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddTransactionScreen(
                        initialType: transaction.type,
                        existingTransaction: transaction,
                      ),
                    ),
                  );
                },
              ),
              const Divider(color: AppTheme.cardDark),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.expense.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.delete_rounded, color: AppTheme.expense),
                ),
                title: const Text('Delete Transaction', style: TextStyle(color: AppTheme.expense, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  final email = context.read<AuthProvider>().userEmail;
                  context.read<TransactionProvider>().deleteTransaction(transaction.id, email: email);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaction deleted')),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
