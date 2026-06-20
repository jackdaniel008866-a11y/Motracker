// Motracker — Stats & Analytics Screen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../providers/transaction_provider.dart';
import '../utils/formatters.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final expenses = provider.categoryExpenses;
        final totalExpense = provider.monthlyExpense;
        
        return SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Analytics',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      // Date Filter Selector
                      SegmentedButton<DateFilter>(
                        segments: const [
                          ButtonSegment(value: DateFilter.thisWeek, label: Text('Week')),
                          ButtonSegment(value: DateFilter.thisMonth, label: Text('Month')),
                          ButtonSegment(value: DateFilter.thisYear, label: Text('Year')),
                          ButtonSegment(value: DateFilter.allTime, label: Text('All')),
                        ],
                        selected: {provider.dateFilter},
                        onSelectionChanged: (Set<DateFilter> newSelection) {
                          provider.setDateFilter(newSelection.first);
                        },
                        style: SegmentedButton.styleFrom(
                          selectedForegroundColor: AppTheme.primaryDark,
                          selectedBackgroundColor: AppTheme.accent,
                          backgroundColor: AppTheme.cardDark,
                          foregroundColor: AppTheme.textSecondary,
                          textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        showSelectedIcon: false,
                      ),
                    ],
                  ),
                ),
              ),
              
              if (totalExpense == 0)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pie_chart_outline_rounded,
                            size: 64,
                            color: AppTheme.textMuted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No expenses this month',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(),
                )
              else ...[
                // Pie Chart
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 300,
                    child: Stack(
                      children: [
                        PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 80,
                            sections: _showingSections(expenses, totalExpense),
                          ),
                        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                        
                        // Center Text
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Total Spent',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Formatters.currencyCompact(totalExpense),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppTheme.expense,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 300.ms),
                      ],
                    ),
                  ),
                ),
                
                // Category List Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                    child: Text(
                      'Spending by Category',
                      style: Theme.of(context).textTheme.titleLarge,
                    ).animate().fadeIn(delay: 400.ms),
                  ),
                ),
                
                // Category List
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = expenses.keys.elementAt(index);
                      final amount = expenses[category]!;
                      final percentage = amount / totalExpense;
                      
                      // Using a consistent color logic based on index for now
                      final color = Colors.primaries[index % Colors.primaries.length];
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                category,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  Formatters.currency(amount),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  Formatters.percentage(percentage),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().slideX(begin: 0.1, end: 0, delay: (500 + (index * 50)).ms).fadeIn();
                    },
                    childCount: expenses.length,
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ],
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _showingSections(Map<String, double> expenses, double totalExpense) {
    return List.generate(expenses.length, (i) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 16.0 : 0.0; // Hide text unless touched
      final radius = isTouched ? 60.0 : 50.0;
      
      final category = expenses.keys.elementAt(i);
      final amount = expenses[category]!;
      final percentage = (amount / totalExpense) * 100;
      
      // We will use standard material colors for now
      final color = Colors.primaries[i % Colors.primaries.length];

      return PieChartSectionData(
        color: color,
        value: amount,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
      );
    });
  }
}
