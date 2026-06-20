// Motracker — Formatters

import 'package:intl/intl.dart';
import '../config/constants.dart';

class Formatters {
  /// Format amount as currency: ₹1,23,456.00
  static String currency(double amount) {
    // Indian number format with commas
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: AppConstants.currencySymbol,
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Format amount as currency with decimals: ₹1,23,456.78
  static String currencyWithDecimals(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: AppConstants.currencySymbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Format amount as compact: ₹1.2L, ₹50K
  static String currencyCompact(double amount) {
    if (amount >= 10000000) {
      return '${AppConstants.currencySymbol}${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '${AppConstants.currencySymbol}${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${AppConstants.currencySymbol}${(amount / 1000).toStringAsFixed(1)}K';
    }
    return currency(amount);
  }

  /// Format date: "19 Jun 2026"
  static String date(DateTime date) {
    return DateFormat(AppConstants.dateFormatDisplay).format(date);
  }

  /// Format date short: "19 Jun"
  static String dateShort(DateTime date) {
    return DateFormat(AppConstants.dateFormatShort).format(date);
  }

  /// Format month: "June 2026"
  static String month(DateTime date) {
    return DateFormat(AppConstants.dateFormatMonth).format(date);
  }

  /// Format month key: "2026-06"
  static String monthKey(DateTime date) {
    return DateFormat(AppConstants.monthKeyFormat).format(date);
  }

  /// Relative date: "Today", "Yesterday", "19 Jun"
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (dateOnly == today.add(const Duration(days: 1))) return 'Tomorrow';
    if (dateOnly.isAfter(today.subtract(const Duration(days: 7)))) {
      return DateFormat('EEEE').format(date); // Day name
    }
    return Formatters.date(date);
  }

  /// Format time: "2:30 PM"
  static String time(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  /// Format frequency: "daily" → "Daily"
  static String frequency(String freq) {
    return freq[0].toUpperCase() + freq.substring(1);
  }

  /// Percentage: 0.756 → "75.6%"
  static String percentage(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }
}
