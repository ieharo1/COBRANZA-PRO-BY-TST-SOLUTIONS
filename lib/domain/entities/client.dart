class Client {
  final int? id;
  final String name;
  final String? phone;
  final String? address;
  final String? notes;
  final String? photoPath;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Client({
    this.id,
    required this.name,
    this.phone,
    this.address,
    this.notes,
    this.photoPath,
    required this.createdAt,
    this.updatedAt,
  });

  Client copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    String? notes,
    String? photoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
      'photoPath': photoPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      notes: map['notes'] as String?,
      photoPath: map['photoPath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt'] as String) 
          : null,
    );
  }

  factory Client.create({
    required String name,
    String? phone,
    String? address,
    String? notes,
    String? photoPath,
  }) {
    return Client(
      name: name,
      phone: phone,
      address: address,
      notes: notes,
      photoPath: photoPath,
      createdAt: DateTime.now(),
    );
  }
}
