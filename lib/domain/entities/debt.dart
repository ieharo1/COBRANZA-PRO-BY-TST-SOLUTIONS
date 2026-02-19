enum DebtStatus {
  pendiente,
  parcial,
  pagada,
  vencida;

  String get displayName {
    switch (this) {
      case DebtStatus.pendiente:
        return 'Pendiente';
      case DebtStatus.parcial:
        return 'Parcial';
      case DebtStatus.pagada:
        return 'Pagada';
      case DebtStatus.vencida:
        return 'Vencida';
    }
  }

  static DebtStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'parcial':
        return DebtStatus.parcial;
      case 'pagada':
        return DebtStatus.pagada;
      case 'vencida':
        return DebtStatus.vencida;
      default:
        return DebtStatus.pendiente;
    }
  }
}

class Debt {
  final int? id;
  final int clientId;
  final String concept;
  final double totalAmount;
  final double paidAmount;
  final DateTime createdAt;
  final DateTime? dueDate;
  final double? interestRate;
  final DebtStatus status;
  final DateTime? updatedAt;

  Debt({
    this.id,
    required this.clientId,
    required this.concept,
    required this.totalAmount,
    this.paidAmount = 0,
    required this.createdAt,
    this.dueDate,
    this.interestRate,
    this.status = DebtStatus.pendiente,
    this.updatedAt,
  });

  double get remainingAmount => totalAmount - paidAmount;
  double get interestAmount => interestRate != null ? totalAmount * (interestRate! / 100) : 0;
  double get totalWithInterest => totalAmount + interestAmount;
  double get remainingWithInterest => remainingAmount + (interestRate != null ? remainingAmount * (interestRate! / 100) : 0);

  bool get isOverdue {
    if (dueDate == null) return false;
    if (status == DebtStatus.pagada) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  DebtStatus get calculatedStatus {
    if (paidAmount >= totalAmount) return DebtStatus.pagada;
    if (paidAmount > 0) return DebtStatus.parcial;
    if (dueDate != null && DateTime.now().isAfter(dueDate!)) return DebtStatus.vencida;
    return status;
  }

  Debt copyWith({
    int? id,
    int? clientId,
    String? concept,
    double? totalAmount,
    double? paidAmount,
    DateTime? createdAt,
    DateTime? dueDate,
    double? interestRate,
    DebtStatus? status,
    DateTime? updatedAt,
  }) {
    return Debt(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      concept: concept ?? this.concept,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      interestRate: interestRate ?? this.interestRate,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'concept': concept,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'interestRate': interestRate,
      'status': status.name,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'] as int?,
      clientId: map['clientId'] as int,
      concept: map['concept'] as String,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate'] as String) : null,
      interestRate: (map['interestRate'] as num?)?.toDouble(),
      status: DebtStatus.fromString(map['status'] as String? ?? 'pendiente'),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
    );
  }
}
