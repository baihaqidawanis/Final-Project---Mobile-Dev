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

  factory MedicineModel.fromMap(Map<String, dynamic> data) {
    return MedicineModel(
      id: data['id'] ?? '',
      pharmacyId: data['pharmacy_id'] ?? data['pharmacyId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? 'Umum',
      isAvailable: data['is_available'] ?? data['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'pharmacy_id': pharmacyId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'is_available': isAvailable,
    };
    if (id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }
}
