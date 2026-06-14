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

  factory PharmacyProfileModel.fromMap(Map<String, dynamic> data) {
    return PharmacyProfileModel(
      uid: data['id'] ?? data['uid'] ?? '',
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      area: data['area'] ?? '',
      phone: data['phone'] ?? '',
      openHours: data['open_hours'] ?? data['openHours'] ?? '08:00 - 21:00',
      rating: (data['rating'] ?? 0).toDouble(),
      totalReviews: data['total_reviews'] ?? data['totalReviews'] ?? 0,
      photoUrl: data['photo_url'] ?? data['photoUrl'] ?? '',
      isOpen: data['is_open'] ?? data['isOpen'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': uid,
        'name': name,
        'address': address,
        'area': area,
        'phone': phone,
        'open_hours': openHours,
        'rating': rating,
        'total_reviews': totalReviews,
        'photo_url': photoUrl,
        'is_open': isOpen,
      };
}
