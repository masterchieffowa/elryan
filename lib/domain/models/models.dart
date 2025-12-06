// Order Status Enum
enum OrderStatus {
  pending,
  inProgress,
  completed,
  delivered;

  String get nameAr {
    switch (this) {
      case OrderStatus.pending:
        return 'قيد الانتظار';
      case OrderStatus.inProgress:
        return 'قيد الإصلاح';
      case OrderStatus.completed:
        return 'مكتمل';
      case OrderStatus.delivered:
        return 'تم التسليم';
    }
  }

  String get nameEn {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.inProgress:
        return 'In Progress';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.delivered:
        return 'Delivered';
    }
  }
}

// Customer Model
class Customer {
  final String id;
  final String name;
  final String phone;
  final String? address;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    required this.createdAt,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Dealer Model (NEW)
class Dealer {
  final String id;
  final String name;
  final String phone;
  final String? address;
  final String? contactPerson;
  final String? email;
  final DateTime createdAt;

  Dealer({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    this.contactPerson,
    this.email,
    required this.createdAt,
  });

  factory Dealer.fromMap(Map<String, dynamic> map) {
    return Dealer(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String?,
      contactPerson: map['contact_person'] as String?,
      email: map['email'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'contact_person': contactPerson,
      'email': email,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Dealer copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? contactPerson,
    String? email,
    DateTime? createdAt,
  }) {
    return Dealer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      contactPerson: contactPerson ?? this.contactPerson,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Accessory Model (Enhanced with category)
class Accessory {
  final String id;
  final String nameAr;
  final String nameEn;
  final String? categoryAr;
  final String? categoryEn;
  final double price;
  final int stockQuantity;
  final DateTime createdAt;

  Accessory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.categoryAr,
    this.categoryEn,
    required this.price,
    required this.stockQuantity,
    required this.createdAt,
  });

  factory Accessory.fromMap(Map<String, dynamic> map) {
    return Accessory(
      id: map['id'] as String,
      nameAr: map['name_ar'] as String,
      nameEn: map['name_en'] as String,
      categoryAr: map['category_ar'] as String?,
      categoryEn: map['category_en'] as String?,
      price: (map['price'] as num).toDouble(),
      stockQuantity: map['stock_quantity'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'category_ar': categoryAr,
      'category_en': categoryEn,
      'price': price,
      'stock_quantity': stockQuantity,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Accessory copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? categoryAr,
    String? categoryEn,
    double? price,
    int? stockQuantity,
    DateTime? createdAt,
  }) {
    return Accessory(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      categoryAr: categoryAr ?? this.categoryAr,
      categoryEn: categoryEn ?? this.categoryEn,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Repair Order Model (Enhanced with serial code and dealer)
class RepairOrder {
  final String id;
  final String serialCode;
  final String? customerId;
  final String? dealerId;
  final String? deviceOwnerName;
  final String laptopType;
  final String problemDescription;
  final double totalCost;
  final double paidAmount;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? deliveredAt;
  final String? notes;
  final List<OrderAccessory> accessories;
  final List<Payment> payments;

  RepairOrder({
    required this.id,
    required this.serialCode,
    this.customerId,
    this.dealerId,
    this.deviceOwnerName,
    required this.laptopType,
    required this.problemDescription,
    required this.totalCost,
    required this.paidAmount,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.deliveredAt,
    this.notes,
    this.accessories = const [],
    this.payments = const [],
  });

  double get remainingAmount => totalCost - paidAmount;

  factory RepairOrder.fromMap(Map<String, dynamic> map) {
    return RepairOrder(
      id: map['id'] as String,
      serialCode: map['serial_code'] as String,
      customerId: map['customer_id'] as String?,
      dealerId: map['dealer_id'] as String?,
      deviceOwnerName: map['device_owner_name'] as String?,
      laptopType: map['laptop_type'] as String,
      problemDescription: map['problem_description'] as String,
      totalCost: (map['total_cost'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      deliveredAt: map['delivered_at'] != null
          ? DateTime.parse(map['delivered_at'] as String)
          : null,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serial_code': serialCode,
      'customer_id': customerId,
      'dealer_id': dealerId,
      'device_owner_name': deviceOwnerName,
      'laptop_type': laptopType,
      'problem_description': problemDescription,
      'total_cost': totalCost,
      'paid_amount': paidAmount,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'notes': notes,
    };
  }

  RepairOrder copyWith({
    String? id,
    String? serialCode,
    String? customerId,
    String? dealerId,
    String? deviceOwnerName,
    String? laptopType,
    String? problemDescription,
    double? totalCost,
    double? paidAmount,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? deliveredAt,
    String? notes,
    List<OrderAccessory>? accessories,
    List<Payment>? payments,
  }) {
    return RepairOrder(
      id: id ?? this.id,
      serialCode: serialCode ?? this.serialCode,
      customerId: customerId ?? this.customerId,
      dealerId: dealerId ?? this.dealerId,
      deviceOwnerName: deviceOwnerName ?? this.deviceOwnerName,
      laptopType: laptopType ?? this.laptopType,
      problemDescription: problemDescription ?? this.problemDescription,
      totalCost: totalCost ?? this.totalCost,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      notes: notes ?? this.notes,
      accessories: accessories ?? this.accessories,
      payments: payments ?? this.payments,
    );
  }
}

// Order Accessory (Junction)
class OrderAccessory {
  final String id;
  final String orderId;
  final String accessoryId;
  final String accessoryNameAr;
  final String accessoryNameEn;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderAccessory({
    required this.id,
    required this.orderId,
    required this.accessoryId,
    required this.accessoryNameAr,
    required this.accessoryNameEn,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderAccessory.fromMap(Map<String, dynamic> map) {
    return OrderAccessory(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      accessoryId: map['accessory_id'] as String,
      accessoryNameAr: map['accessory_name_ar'] as String,
      accessoryNameEn: map['accessory_name_en'] as String,
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'accessory_id': accessoryId,
      'accessory_name_ar': accessoryNameAr,
      'accessory_name_en': accessoryNameEn,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }
}

// Payment Model
class Payment {
  final String id;
  final String orderId;
  final double amount;
  final DateTime paymentDate;
  final String? notes;

  Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.paymentDate,
    this.notes,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(map['payment_date'] as String),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'notes': notes,
    };
  }
}
