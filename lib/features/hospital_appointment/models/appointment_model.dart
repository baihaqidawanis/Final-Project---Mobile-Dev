import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String appointmentId;
  final String familyId;
  final String hospitalId;
  final String dateString; // Format: YYYY-MM-DD
  final String timeSlot; // Format: HH:MM
  final String status;

  AppointmentModel({
    required this.appointmentId,
    required this.familyId,
    required this.hospitalId,
    required this.dateString,
    required this.timeSlot,
    required this.status,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> data, String documentId) {
    return AppointmentModel(
      appointmentId: documentId,
      familyId: data['familyId'] ?? '',
      hospitalId: data['hospitalId'] ?? '',
      dateString: data['dateString'] ?? '',
      timeSlot: data['timeSlot'] ?? '',
      status: data['status'] ?? 'pending',
    );
  }

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppointmentModel(
      appointmentId: doc.id,
      familyId: data['familyId'] ?? '',
      hospitalId: data['hospitalId'] ?? '',
      dateString: data['dateString'] ?? '',
      timeSlot: data['timeSlot'] ?? '',
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'hospitalId': hospitalId,
      'dateString': dateString,
      'timeSlot': timeSlot,
      'status': status,
    };
  }

  AppointmentModel copyWith({
    String? appointmentId,
    String? familyId,
    String? hospitalId,
    String? dateString,
    String? timeSlot,
    String? status,
  }) {
    return AppointmentModel(
      appointmentId: appointmentId ?? this.appointmentId,
      familyId: familyId ?? this.familyId,
      hospitalId: hospitalId ?? this.hospitalId,
      dateString: dateString ?? this.dateString,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
    );
  }
}
