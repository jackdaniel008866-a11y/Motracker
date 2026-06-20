// Motracker — Category Model & Definitions

import 'package:flutter/material.dart';

class Category {
  final String? id;
  final String name;
  final IconData icon;
  final Color color;
  final String type; // 'income', 'expense', or 'both'
  final bool isCustom;

  const Category({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isCustom = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'colorHex': color.value,
      'type': type,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      icon: IconData(
        map['iconCodePoint'],
        fontFamily: map['iconFontFamily'] ?? 'MaterialIcons',
      ),
      color: Color(map['colorHex']),
      type: map['type'],
      isCustom: true,
    );
  }
}

class AppCategories {
  // ============================================
  // Expense Categories
  // ============================================
  static const List<Category> expense = [
    Category(name: 'Food', icon: Icons.restaurant_rounded, color: Color(0xFFFF6B6B), type: 'expense'),
    Category(name: 'Transport', icon: Icons.directions_car_rounded, color: Color(0xFF4ECDC4), type: 'expense'),
    Category(name: 'Rent', icon: Icons.home_rounded, color: Color(0xFF45B7D1), type: 'expense'),
    Category(name: 'Bills', icon: Icons.receipt_long_rounded, color: Color(0xFFFFA07A), type: 'expense'),
    Category(name: 'Shopping', icon: Icons.shopping_bag_rounded, color: Color(0xFFDDA0DD), type: 'expense'),
    Category(name: 'Health', icon: Icons.local_hospital_rounded, color: Color(0xFF98D8C8), type: 'expense'),
    Category(name: 'Entertainment', icon: Icons.movie_rounded, color: Color(0xFFFF8A65), type: 'expense'),
    Category(name: 'Education', icon: Icons.school_rounded, color: Color(0xFF7986CB), type: 'expense'),
    Category(name: 'Work', icon: Icons.work_rounded, color: Color(0xFF90CAF9), type: 'expense'),
    Category(name: 'Gifts', icon: Icons.card_giftcard_rounded, color: Color(0xFFEF5350), type: 'expense'),
    Category(name: 'Recharge', icon: Icons.phone_android_rounded, color: Color(0xFF66BB6A), type: 'expense'),
    Category(name: 'Maintenance', icon: Icons.build_rounded, color: Color(0xFFBCAAA4), type: 'expense'),
    Category(name: 'Groceries', icon: Icons.local_grocery_store_rounded, color: Color(0xFF81C784), type: 'expense'),
    Category(name: 'Subscriptions', icon: Icons.subscriptions_rounded, color: Color(0xFFBA68C8), type: 'expense'),
    Category(name: 'Other', icon: Icons.more_horiz_rounded, color: Color(0xFF78909C), type: 'expense'),
  ];

  // ============================================
  // Income Categories
  // ============================================
  static const List<Category> income = [
    Category(name: 'Salary', icon: Icons.account_balance_wallet_rounded, color: Color(0xFF4CAF50), type: 'income'),
    Category(name: 'Freelance', icon: Icons.laptop_mac_rounded, color: Color(0xFF26A69A), type: 'income'),
    Category(name: 'Investment', icon: Icons.trending_up_rounded, color: Color(0xFF42A5F5), type: 'income'),
    Category(name: 'Gift', icon: Icons.card_giftcard_rounded, color: Color(0xFFEF5350), type: 'income'),
    Category(name: 'Refund', icon: Icons.replay_rounded, color: Color(0xFFFFCA28), type: 'income'),
    Category(name: 'Interest', icon: Icons.percent_rounded, color: Color(0xFF5C6BC0), type: 'income'),
    Category(name: 'Other', icon: Icons.more_horiz_rounded, color: Color(0xFF78909C), type: 'income'),
  ];

  /// Get all categories for a given type
  static List<Category> getByType(String type) {
    if (type == 'income') return income;
    return expense;
  }

  /// Find a category by name and type
  static Category? find(String name, String type) {
    final list = getByType(type);
    try {
      return list.firstWhere((c) => c.name == name);
    } catch (_) {
      return list.last; // Return "Other" as fallback
    }
  }

  /// Get icon for a category name
  static IconData getIcon(String name, String type) {
    return find(name, type)?.icon ?? Icons.more_horiz_rounded;
  }

  /// Get color for a category name
  static Color getColor(String name, String type) {
    return find(name, type)?.color ?? const Color(0xFF78909C);
  }
}
