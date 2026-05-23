import 'package:cloud_firestore/cloud_firestore.dart';

class CaregiverProfileModel {
  final String uid;
  final String name;
  final String specialization;
  final double pricePerHour;
  final double rating;
  final int totalReviews;
  final String photoUrl;
  final String bio;
  final String area;
  final bool isAvailable;

  const CaregiverProfileModel({
    required this.uid,
    required this.name,
    required this.specialization,
    required this.pricePerHour,
    required this.rating,
    required this.totalReviews,
    required this.photoUrl,
    required this.bio,
    required this.area,
    required this.isAvailable,
  });

  factory CaregiverProfileModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CaregiverProfileModel(
      uid: doc.id,
      name: data['name'] ?? '',
      specialization: data['specialization'] ?? '',
      pricePerHour: (data['pricePerHour'] ?? 0).toDouble(),
      rating: (data['rating'] ?? 0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      photoUrl: data['photoUrl'] ?? '',
      bio: data['bio'] ?? '',
      area: data['area'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'specialization': specialization,
      'pricePerHour': pricePerHour,
      'rating': rating,
      'totalReviews': totalReviews,
      'photoUrl': photoUrl,
      'bio': bio,
      'area': area,
      'isAvailable': isAvailable,
    };
  }
}
