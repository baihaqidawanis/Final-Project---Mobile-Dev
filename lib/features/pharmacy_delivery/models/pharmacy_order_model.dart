enum PharmacyOrderStatus { pending, accepted, shipped, delivered, cancelled }

class OrderItem {
  final String medicineId;
  final String medicineName;
  final double price;
  final int quantity;

  const OrderItem({
    required this.medicineId,
    required this.medicineName,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toMap() => {
    'medicine_id': medicineId,
    'medicine_name': medicineName,
    'price': price,
    'quantity': quantity,
  };

  factory OrderItem.fromMap(Map<String, dynamic> data) => OrderItem(
    medicineId: data['medicine_id'] ?? data['medicineId'] ?? '',
    medicineName: data['medicine_name'] ?? data['medicineName'] ?? '',
    price: (data['price'] ?? 0).toDouble(),
    quantity: data['quantity'] ?? 1,
  );
}

class PharmacyOrderModel {
  final String orderId;
  final String userId;
  final String userName;
  final String pharmacyId;
  final String pharmacyName;
  final List<OrderItem> items;
  final double totalPrice;
  final String deliveryAddress;
  final String notes;
  final String? prescriptionImageUrl;
  final String? prescriptionImagePath;
  final PharmacyOrderStatus status;
  final DateTime createdAt;
  final double? rating;
  final String? review;

  const PharmacyOrderModel({
    required this.orderId,
    required this.userId,
    required this.userName,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.items,
    required this.totalPrice,
    required this.deliveryAddress,
    required this.notes,
    this.prescriptionImageUrl,
    this.prescriptionImagePath,
    required this.status,
    required this.createdAt,
    this.rating,
    this.review,
  });

  static PharmacyOrderStatus _parseStatus(String? s) {
    switch (s) {
      case 'accepted':
      case 'processing':
        return PharmacyOrderStatus.accepted;
      case 'shipped':
        return PharmacyOrderStatus.shipped;
      case 'delivered':
        return PharmacyOrderStatus.delivered;
      case 'cancelled':
        return PharmacyOrderStatus.cancelled;
      default:
        return PharmacyOrderStatus.pending;
    }
  }

  static String statusToString(PharmacyOrderStatus s) {
    switch (s) {
      case PharmacyOrderStatus.pending:
        return 'pending';
      case PharmacyOrderStatus.accepted:
        return 'accepted';
      case PharmacyOrderStatus.shipped:
        return 'shipped';
      case PharmacyOrderStatus.delivered:
        return 'delivered';
      case PharmacyOrderStatus.cancelled:
        return 'cancelled';
    }
  }

  factory PharmacyOrderModel.fromMap(Map<String, dynamic> data) {
    final itemsList = (data['items'] as List<dynamic>? ?? [])
        .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
        .toList();
    return PharmacyOrderModel(
      orderId: data['id'] ?? '',
      userId: data['user_id'] ?? data['userId'] ?? '',
      userName: data['user_name'] ?? data['userName'] ?? '',
      pharmacyId: data['pharmacy_id'] ?? data['pharmacyId'] ?? '',
      pharmacyName: data['pharmacy_name'] ?? data['pharmacyName'] ?? '',
      items: itemsList,
      totalPrice: (data['total_price'] ?? data['totalPrice'] ?? 0).toDouble(),
      deliveryAddress: data['delivery_address'] ?? data['deliveryAddress'] ?? '',
      notes: data['notes'] ?? '',
      prescriptionImageUrl: data['prescription_url'] ?? data['prescriptionImageUrl'] as String?,
      prescriptionImagePath: data['prescription_path'] ?? data['prescriptionImagePath'] as String?,
      status: _parseStatus(data['status']),
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'] as String)
          : DateTime.now(),
      rating: data['rating'] != null ? (data['rating'] as num).toDouble() : null,
      review: data['review'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'user_id': userId,
      'user_name': userName,
      'pharmacy_id': pharmacyId,
      'pharmacy_name': pharmacyName,
      'items': items.map((e) => e.toMap()).toList(),
      'total_price': totalPrice,
      'delivery_address': deliveryAddress,
      'notes': notes,
      if (prescriptionImageUrl != null)
        'prescription_url': prescriptionImageUrl,
      if (prescriptionImagePath != null)
        'prescription_path': prescriptionImagePath,
      'status': statusToString(status),
      'created_at': createdAt.toIso8601String(),
      if (rating != null) 'rating': rating,
      if (review != null) 'review': review,
    };
    if (orderId.isNotEmpty) {
      map['id'] = orderId;
    }
    return map;
  }
}
