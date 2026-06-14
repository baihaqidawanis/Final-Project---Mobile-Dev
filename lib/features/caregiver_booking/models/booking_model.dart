enum BookingStatus { pending, accepted, completed, cancelled }

class BookingModel {
  final String bookingId;
  final String familyId;
  final String caregiverId;
  final String caregiverName;
  final String familyName;
  final DateTime dateTime;
  final String specialization;
  final double pricePerHour;
  final String notes;
  final String clinicalNote; // written by caregiver on completion
  final BookingStatus status;
  final DateTime createdAt;

  const BookingModel({
    required this.bookingId,
    required this.familyId,
    required this.caregiverId,
    required this.caregiverName,
    required this.familyName,
    required this.dateTime,
    required this.specialization,
    required this.pricePerHour,
    required this.notes,
    this.clinicalNote = '',
    required this.status,
    required this.createdAt,
  });

  static BookingStatus _parseStatus(String? s) {
    switch (s) {
      case 'accepted':
        return BookingStatus.accepted;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }

  static String statusToString(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.accepted:
        return 'accepted';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
    }
  }

  factory BookingModel.fromMap(Map<String, dynamic> data) {
    return BookingModel(
      bookingId: data['id'] ?? '',
      familyId: data['family_id'] ?? '',
      caregiverId: data['caregiver_id'] ?? '',
      caregiverName: data['caregiver_name'] ?? '',
      familyName: data['family_name'] ?? '',
      dateTime: data['date_time'] != null
          ? DateTime.parse(data['date_time'] as String)
          : DateTime.now(),
      specialization: data['specialization'] ?? '',
      pricePerHour: (data['price_per_hour'] ?? 0).toDouble(),
      notes: data['notes'] ?? '',
      clinicalNote: data['clinical_note'] ?? '',
      status: _parseStatus(data['status']),
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'family_id': familyId,
      'caregiver_id': caregiverId,
      'caregiver_name': caregiverName,
      'family_name': familyName,
      'date_time': dateTime.toIso8601String(),
      'specialization': specialization,
      'price_per_hour': pricePerHour,
      'notes': notes,
      'status': statusToString(status),
      'created_at': createdAt.toIso8601String(),
      'clinical_note': clinicalNote,
    };
    if (bookingId.isNotEmpty) {
      map['id'] = bookingId;
    }
    return map;
  }
}
