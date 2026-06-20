import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../models/category.dart';
import '../providers/budget_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/formatters.dart';

class AddBudgetSheet extends StatefulWidget {
  const AddBudgetSheet({super.key});

  @override
  State<AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<AddBudgetSheet> {
  final _amountController = TextEditingController();
  String? _selectedCategory;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_amountController.text.isEmpty || _selectedCategory == null) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    setState(() => _isSubmitting = true);

    try {
      final email = context.read<AuthProvider>().userEmail;
      final currentMonth = Formatters.monthKey(DateTime.now());
      
      await context.read<BudgetProvider>().addBudget(
        category: _selectedCategory!,
        limit: amount,
        month: currentMonth,
        email: email,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show expense categories for budgets
    final allCategories = [...AppCategories.expense, ...AppCategories.income];
    final categories = allCategories
        .where((c) => c.type == 'expense' || c.type == 'both')
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Set Monthly Budget',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Amount Input
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: Theme.of(context).textTheme.displayMedium,
              decoration: InputDecoration(
                hintText: '0',
                prefixText: AppConstants.currencySymbol,
                prefixStyle: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppTheme.textMuted,
                ),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 24),

            // Category Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  hint: const Text('Select Category'),
                  isExpanded: true,
                  dropdownColor: AppTheme.cardDarkAlt,
                  items: categories.map((c) {
                    return DropdownMenuItem(
                      value: c.name,
                      child: Row(
                        children: [
                          Icon(c.icon, color: c.color, size: 20),
                          const SizedBox(width: 12),
                          Text(c.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedCategory = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Budget'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
