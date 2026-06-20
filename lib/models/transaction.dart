// Motracker — Data Models

// ============================================
// Transaction Model
// ============================================

class Transaction {
  final String id;
  final double amount;
  final String type; // 'income' or 'expense'
  final String category;
  final String note;
  final DateTime date;
  final DateTime createdAt;
  final bool isSynced;

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    this.note = '',
    required this.date,
    DateTime? createdAt,
    this.isSynced = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Transaction copyWith({
    String? id,
    double? amount,
    String? type,
    String? category,
    String? note,
    DateTime? date,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'category': category,
      'note': note,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      category: map['category'] as String,
      note: map['note'] as String? ?? '',
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      isSynced: map['isSynced'] == 1 || map['isSynced'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'category': category,
      'note': note,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      type: json['type']?.toString() ?? 'expense',
      category: json['category']?.toString() ?? 'Other',
      note: json['note']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      isSynced: true,
    );
  }
}
