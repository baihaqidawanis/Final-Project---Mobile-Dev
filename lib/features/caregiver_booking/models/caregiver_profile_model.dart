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

  factory CaregiverProfileModel.fromMap(Map<String, dynamic> data) {
    return CaregiverProfileModel(
      uid: data['id'] ?? data['uid'] ?? '',
      name: data['name'] ?? '',
      specialization: data['specialization'] ?? '',
      pricePerHour: (data['price_per_hour'] ?? data['pricePerHour'] ?? 0).toDouble(),
      rating: (data['rating'] ?? 0).toDouble(),
      totalReviews: data['total_reviews'] ?? data['totalReviews'] ?? 0,
      photoUrl: data['photo_url'] ?? data['photoUrl'] ?? '',
      bio: data['bio'] ?? '',
      area: data['area'] ?? '',
      isAvailable: data['is_available'] ?? data['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'name': name,
      'specialization': specialization,
      'price_per_hour': pricePerHour,
      'rating': rating,
      'total_reviews': totalReviews,
      'photo_url': photoUrl,
      'bio': bio,
      'area': area,
      'is_available': isAvailable,
    };
  }
}
