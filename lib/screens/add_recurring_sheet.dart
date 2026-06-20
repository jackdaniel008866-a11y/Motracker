import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../models/category.dart';
import '../providers/recurring_transaction_provider.dart';
import '../providers/auth_provider.dart';

class AddRecurringSheet extends StatefulWidget {
  const AddRecurringSheet({super.key});

  @override
  State<AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends State<AddRecurringSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedType = 'expense';
  String? _selectedCategory;
  String _selectedFrequency = 'monthly';
  DateTime _startDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_amountController.text.isEmpty || _selectedCategory == null) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    setState(() => _isSubmitting = true);

    try {
      final email = context.read<AuthProvider>().userEmail;
      
      await context.read<RecurringTransactionProvider>().addRecurringTransaction(
        amount: amount,
        type: _selectedType,
        category: _selectedCategory!,
        note: _noteController.text.trim(),
        frequency: _selectedFrequency,
        startDate: _startDate,
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
    final allCategories = [...AppCategories.expense, ...AppCategories.income];
    final categories = allCategories
        .where((c) => c.type == _selectedType || c.type == 'both')
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'New Recurring',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Type Selector
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Expense')),
                  ButtonSegment(value: 'income', label: Text('Income')),
                ],
                selected: {_selectedType},
                onSelectionChanged: (val) {
                  setState(() {
                    _selectedType = val.first;
                    _selectedCategory = null;
                  });
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: _selectedType == 'income' ? AppTheme.income : AppTheme.expense,
                  selectedForegroundColor: Colors.white,
                  backgroundColor: AppTheme.cardDark,
                ),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 24),

              // Amount Input
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: _selectedType == 'income' ? AppTheme.income : AppTheme.expense,
                ),
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
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Frequency Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFrequency,
                    isExpanded: true,
                    dropdownColor: AppTheme.cardDarkAlt,
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                      DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                    ],
                    onChanged: (val) => setState(() => _selectedFrequency = val!),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Note Input
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: 'Note (Optional)',
                  prefixIcon: const Icon(Icons.notes_rounded, color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.cardDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Start Date Picker
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() => _startDate = date);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: AppTheme.textMuted),
                      const SizedBox(width: 16),
                      Text(
                        'Starts: ${_startDate.day}/${_startDate.month}/${_startDate.year}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
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
                      : const Text('Save Auto-Transaction'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
