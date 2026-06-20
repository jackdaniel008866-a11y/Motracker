// Motracker — Budget Model

class Budget {
  final String id;
  final String category;
  final double limit;
  final String month; // Format: "2026-06"
  final bool isSynced;

  Budget({
    required this.id,
    required this.category,
    required this.limit,
    required this.month,
    this.isSynced = false,
  });

  Budget copyWith({
    String? id,
    String? category,
    double? limit,
    String? month,
    bool? isSynced,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      limit: limit ?? this.limit,
      month: month ?? this.month,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'budgetLimit': limit,
      'month': month,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      category: map['category'] as String,
      limit: (map['budgetLimit'] as num).toDouble(),
      month: map['month'] as String,
      isSynced: map['isSynced'] == 1 || map['isSynced'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'limit': limit,
      'month': month,
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      limit: (json['limit'] is num) ? (json['limit'] as num).toDouble() : double.tryParse(json['limit']?.toString() ?? '0') ?? 0,
      month: json['month']?.toString() ?? '',
      isSynced: true,
    );
  }
}
