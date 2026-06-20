// Motracker — Add Transaction Screen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../models/category.dart' as app_cat;
import '../models/transaction.dart' as app;
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/formatters.dart';
import '../services/database_service.dart';
import '../widgets/bouncy_card.dart';

class AddTransactionScreen extends StatefulWidget {
  final String initialType;
  final app.Transaction? existingTransaction;
  
  const AddTransactionScreen({
    super.key,
    this.initialType = AppConstants.typeExpense,
    this.existingTransaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late String _type;
  app_cat.Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  bool _isSplit = false;
  double _splitPercentage = 50.0;
  bool _isSaving = false;
  
  final _db = DatabaseService();
  List<app_cat.Category> _customCategories = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      final t = widget.existingTransaction!;
      _type = t.type;
      _amountController.text = t.amount.toStringAsFixed(2).replaceAll('.00', '');
      _noteController.text = t.note;
      _selectedDate = t.date;
      // We will set category below, it depends on AppCategories.getByType
      _selectedCategory = app_cat.AppCategories.getByType(_type).firstWhere(
        (c) => c.id == t.category,
        orElse: () => app_cat.AppCategories.getByType(_type).first,
      );
    } else {
      _type = widget.initialType;
    }
    _loadCustomCategories();
  }

  Future<void> _loadCustomCategories() async {
    final list = await _db.getCustomCategories();
    setState(() {
      _customCategories = list.map((map) => app_cat.Category.fromMap(map)).toList();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultCats = app_cat.AppCategories.getByType(_type);
    final typeCustom = _customCategories.where((c) => c.type == _type).toList();
    final categories = [
      ...defaultCats.where((c) => c.name != 'Other'),
      ...typeCustom,
      defaultCats.firstWhere((c) => c.name == 'Other', orElse: () => defaultCats.last)
    ];
    
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(widget.existingTransaction != null 
            ? 'Edit ${_type == AppConstants.typeExpense ? "Expense" : "Income"}'
            : 'Add ${_type == AppConstants.typeExpense ? "Expense" : "Income"}'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Type Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: _TypeToggle(
                    title: 'Expense',
                    isSelected: _type == AppConstants.typeExpense,
                    color: AppTheme.expense,
                    onTap: () {
                      setState(() {
                        _type = AppConstants.typeExpense;
                        _selectedCategory = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TypeToggle(
                    title: 'Income',
                    isSelected: _type == AppConstants.typeIncome,
                    color: AppTheme.income,
                    onTap: () {
                      setState(() {
                        _type = AppConstants.typeIncome;
                        _selectedCategory = null;
                      });
                    },
                  ),
                ),
              ],
            ).animate().slideY(begin: -0.2, end: 0, duration: 400.ms).fadeIn(),
          ),
          
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Amount Input
                          Text(
                            'Amount',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: _type == AppConstants.typeExpense ? AppTheme.expense : AppTheme.income,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              prefixText: '${AppConstants.currencySymbol} ',
                              prefixStyle: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: _type == AppConstants.typeExpense ? AppTheme.expense : AppTheme.income,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ).animate().fadeIn(delay: 200.ms),
                          
                          const SizedBox(height: 32),
                          
                          // Date & Note Row
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardDark,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, color: AppTheme.accent, size: 20),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            Formatters.dateShort(_selectedDate),
                                            style: Theme.of(context).textTheme.bodyLarge,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _noteController,
                                  decoration: InputDecoration(
                                    hintText: 'Note (optional)',
                                    prefixIcon: const Icon(Icons.edit_note_rounded, color: AppTheme.textMuted),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ).animate().slideY(begin: 0.1, end: 0, delay: 300.ms).fadeIn(),
                          
                          const SizedBox(height: 24),
                          
                          // Split Bill Toggle
                          if (_type == AppConstants.typeExpense) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.cardDark,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.call_split_rounded, color: AppTheme.accent, size: 20),
                                          const SizedBox(width: 12),
                                          Text('Split Bill', style: Theme.of(context).textTheme.bodyLarge),
                                        ],
                                      ),
                                      Switch(
                                        value: _isSplit,
                                        onChanged: (val) => setState(() => _isSplit = val),
                                        activeColor: AppTheme.accent,
                                      ),
                                    ],
                                  ),
                                  if (_isSplit) ...[
                                    const Divider(color: AppTheme.cardDarkAlt),
                                    Row(
                                      children: [
                                        Text('My Share:', style: Theme.of(context).textTheme.bodyMedium),
                                        Expanded(
                                          child: Slider(
                                            value: _splitPercentage,
                                            min: 10,
                                            max: 90,
                                            divisions: 8,
                                            label: '${_splitPercentage.round()}%',
                                            activeColor: AppTheme.accent,
                                            onChanged: (val) => setState(() => _splitPercentage = val),
                                          ),
                                        ),
                                        Text('${_splitPercentage.round()}%', style: Theme.of(context).textTheme.titleMedium),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ).animate().fadeIn(delay: 350.ms),
                            const SizedBox(height: 24),
                          ],
                          
                          // Category Selection
                          Text(
                            'Category',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  
                  // Category Grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 0,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.9,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final category = categories[index];
                          final isSelected = _selectedCategory?.name == category.name;
                          
                          return _CategoryItem(
                            category: category,
                            isSelected: isSelected,
                            onTap: () async {
                              if (category.name == 'Other') {
                                final customName = await _showCustomCategoryDialog();
                                if (customName != null && customName.trim().isNotEmpty) {
                                  final newCat = app_cat.Category(
                                    name: customName.trim(),
                                    icon: Icons.star_rounded,
                                    color: Colors.grey,
                                    type: _type,
                                    isCustom: true,
                                  );
                                  await _db.insertCustomCategory(newCat.toMap());
                                  await _loadCustomCategories();
                                  setState(() {
                                    _selectedCategory = newCat;
                                  });
                                }
                              } else {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              }
                            },
                          ).animate().fadeIn(delay: (400 + (index * 20)).ms);
                        },
                        childCount: categories.length,
                      ),
                    ),
                  ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 150)),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        color: AppTheme.surfaceDark,
        padding: const EdgeInsets.all(24.0),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveTransaction,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryDark,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Save Transaction'),
        ),
      ),
    );
  }

  Future<String?> _showCustomCategoryDialog() async {
    String name = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Custom Category', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter category name',
          ),
          onChanged: (val) => name = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, name),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accent,
              onPrimary: AppTheme.primaryDark,
              surface: AppTheme.cardDark,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    double amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_isSplit && _type == AppConstants.typeExpense) {
      amount = amount * (_splitPercentage / 100);
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final email = context.read<AuthProvider>().userEmail;
      if (widget.existingTransaction != null) {
        final updatedTransaction = app.Transaction(
          id: widget.existingTransaction!.id,
          amount: amount,
          type: _type,
          category: _selectedCategory!.name,
          note: _noteController.text.trim(),
          date: _selectedDate,
        );
        await context.read<TransactionProvider>().updateTransaction(updatedTransaction, email: email);
      } else {
        await context.read<TransactionProvider>().addTransaction(
          amount: amount,
          type: _type,
          category: _selectedCategory!.name,
          note: _noteController.text.trim(),
          date: _selectedDate,
          email: email,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction saved'),
            backgroundColor: AppTheme.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }


}

class _TypeToggle extends StatelessWidget {
  final String title;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeToggle({
    required this.title,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BouncyCard(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.5) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isSelected ? color : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final app_cat.Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BouncyCard(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? category.color.withValues(alpha: 0.2) : AppTheme.cardDark,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? category.color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              category.icon,
              color: isSelected ? category.color : AppTheme.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            category.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
