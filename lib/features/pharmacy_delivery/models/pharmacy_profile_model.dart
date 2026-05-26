import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacyProfileModel {
  final String uid;
  final String name;
  final String address;
  final String area;
  final String phone;
  final String openHours;
  final double rating;
  final int totalReviews;
  final String photoUrl;
  final bool isOpen;

  const PharmacyProfileModel({
    required this.uid,
    required this.name,
    required this.address,
    required this.area,
    required this.phone,
    required this.openHours,
    required this.rating,
    required this.totalReviews,
    required this.photoUrl,
    required this.isOpen,
  });

  factory PharmacyProfileModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PharmacyProfileModel(
      uid: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      area: data['area'] ?? '',
      phone: data['phone'] ?? '',
      openHours: data['openHours'] ?? '08:00 - 21:00',
      rating: (data['rating'] ?? 0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      photoUrl: data['photoUrl'] ?? '',
      isOpen: data['isOpen'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'address': address,
        'area': area,
        'phone': phone,
        'openHours': openHours,
        'rating': rating,
        'totalReviews': totalReviews,
        'photoUrl': photoUrl,
        'isOpen': isOpen,
      };
}
