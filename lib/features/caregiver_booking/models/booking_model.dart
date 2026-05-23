import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory BookingModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return BookingModel(
      bookingId: doc.id,
      familyId: data['familyId'] ?? '',
      caregiverId: data['caregiverId'] ?? '',
      caregiverName: data['caregiverName'] ?? '',
      familyName: data['familyName'] ?? '',
      dateTime:
          (data['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      specialization: data['specialization'] ?? '',
      pricePerHour: (data['pricePerHour'] ?? 0).toDouble(),
      notes: data['notes'] ?? '',
      status: _parseStatus(data['status']),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'caregiverId': caregiverId,
      'caregiverName': caregiverName,
      'familyName': familyName,
      'dateTime': Timestamp.fromDate(dateTime),
      'specialization': specialization,
      'pricePerHour': pricePerHour,
      'notes': notes,
      'status': statusToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
