enum PaymentMethod {
  efectivo,
  transferencia,
  tarjeta,
  cheque,
  otro;

  String get displayName {
    switch (this) {
      case PaymentMethod.efectivo:
        return 'Efectivo';
      case PaymentMethod.transferencia:
        return 'Transferencia';
      case PaymentMethod.tarjeta:
        return 'Tarjeta';
      case PaymentMethod.cheque:
        return 'Cheque';
      case PaymentMethod.otro:
        return 'Otro';
    }
  }

  static PaymentMethod fromString(String value) {
    switch (value.toLowerCase()) {
      case 'transferencia':
        return PaymentMethod.transferencia;
      case 'tarjeta':
        return PaymentMethod.tarjeta;
      case 'cheque':
        return PaymentMethod.cheque;
      case 'otro':
        return PaymentMethod.otro;
      default:
        return PaymentMethod.efectivo;
    }
  }
}

class Payment {
  final int? id;
  final int debtId;
  final int clientId;
  final double amount;
  final PaymentMethod method;
  final DateTime createdAt;
  final String? notes;

  Payment({
    this.id,
    required this.debtId,
    required this.clientId,
    required this.amount,
    this.method = PaymentMethod.efectivo,
    required this.createdAt,
    this.notes,
  });

  Payment copyWith({
    int? id,
    int? debtId,
    int? clientId,
    double? amount,
    PaymentMethod? method,
    DateTime? createdAt,
    String? notes,
  }) {
    return Payment(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      clientId: clientId ?? this.clientId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debtId': debtId,
      'clientId': clientId,
      'amount': amount,
      'method': method.name,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      debtId: map['debtId'] as int,
      clientId: map['clientId'] as int,
      amount: (map['amount'] as num).toDouble(),
      method: PaymentMethod.fromString(map['method'] as String? ?? 'efectivo'),
      createdAt: DateTime.parse(map['createdAt'] as String),
      notes: map['notes'] as String?,
    );
  }
}
