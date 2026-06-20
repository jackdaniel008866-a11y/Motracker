// Motracker — Recurring Transaction Model

class RecurringTransaction {
  final String id;
  final double amount;
  final String type; // 'income' or 'expense'
  final String category;
  final String note;
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final bool isSynced;

  RecurringTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    this.note = '',
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.isSynced = false,
  });

  RecurringTransaction copyWith({
    String? id,
    double? amount,
    String? type,
    String? category,
    String? note,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? isSynced,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      note: note ?? this.note,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
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
      'frequency': frequency,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    return RecurringTransaction(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      category: map['category'] as String,
      note: map['note'] as String? ?? '',
      frequency: map['frequency'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate'] as String) : null,
      isActive: map['isActive'] == 1 || map['isActive'] == true,
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
      'frequency': frequency,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String() ?? '',
      'isActive': isActive,
    };
  }

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      type: json['type']?.toString() ?? 'expense',
      category: json['category']?.toString() ?? 'Other',
      note: json['note']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? 'monthly',
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ?? DateTime.now(),
      endDate: json['endDate'] != null && json['endDate'].toString().isNotEmpty
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
      isActive: json['isActive'] == true || json['isActive'] == 'true',
      isSynced: true,
    );
  }

  /// Check if this recurring transaction should generate an entry for the given date
  bool shouldGenerateFor(DateTime date) {
    if (!isActive) return false;
    if (date.isBefore(startDate)) return false;
    if (endDate != null && date.isAfter(endDate!)) return false;

    switch (frequency) {
      case 'daily':
        return true;
      case 'weekly':
        return date.weekday == startDate.weekday;
      case 'monthly':
        return date.day == startDate.day;
      case 'yearly':
        return date.month == startDate.month && date.day == startDate.day;
      default:
        return false;
    }
  }
}
