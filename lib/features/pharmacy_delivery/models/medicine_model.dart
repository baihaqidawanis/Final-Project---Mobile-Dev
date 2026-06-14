import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineModel {
  final String id;
  final String pharmacyId;
  final String name;
  final String description;
  final double price;
  final String category;
  final bool isAvailable;

  const MedicineModel({
    required this.id,
    required this.pharmacyId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.isAvailable,
  });

  factory MedicineModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MedicineModel(
      id: doc.id,
      pharmacyId: data['pharmacyId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? 'Umum',
      isAvailable: data['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'pharmacyId': pharmacyId,
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'isAvailable': isAvailable,
      };
}
