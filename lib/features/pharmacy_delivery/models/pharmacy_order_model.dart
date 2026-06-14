import 'package:cloud_firestore/cloud_firestore.dart';

// pending → accepted (apotek terima & kemas) → shipped (dikirim)
// → delivered (customer konfirmasi) | cancelled
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
    'medicineId': medicineId,
    'medicineName': medicineName,
    'price': price,
    'quantity': quantity,
  };

  factory OrderItem.fromMap(Map<String, dynamic> data) => OrderItem(
    medicineId: data['medicineId'] ?? '',
    medicineName: data['medicineName'] ?? '',
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
      case 'processing': // backward compat
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

  factory PharmacyOrderModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final itemsList = (data['items'] as List<dynamic>? ?? [])
        .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
        .toList();
    return PharmacyOrderModel(
      orderId: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      pharmacyId: data['pharmacyId'] ?? '',
      pharmacyName: data['pharmacyName'] ?? '',
      items: itemsList,
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      deliveryAddress: data['deliveryAddress'] ?? '',
      notes: data['notes'] ?? '',
      prescriptionImageUrl: data['prescriptionImageUrl'] as String?,
      prescriptionImagePath: data['prescriptionImagePath'] as String?,
      status: _parseStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rating: data['rating'] != null
          ? (data['rating'] as num).toDouble()
          : null,
      review: data['review'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userName': userName,
    'pharmacyId': pharmacyId,
    'pharmacyName': pharmacyName,
    'items': items.map((e) => e.toMap()).toList(),
    'totalPrice': totalPrice,
    'deliveryAddress': deliveryAddress,
    'notes': notes,
    if (prescriptionImageUrl != null)
      'prescriptionImageUrl': prescriptionImageUrl,
    if (prescriptionImagePath != null)
      'prescriptionImagePath': prescriptionImagePath,
    'status': statusToString(status),
    'createdAt': Timestamp.fromDate(createdAt),
    if (rating != null) 'rating': rating,
    if (review != null) 'review': review,
  };
}
