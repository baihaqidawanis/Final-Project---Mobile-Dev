class AppointmentModel {
  final String appointmentId;
  final String familyId;
  final String hospitalId;
  final String dateString; // Format: YYYY-MM-DD
  final String timeSlot; // Format: HH:MM
  final String status;
  final String patientName;
  final String symptoms;

  AppointmentModel({
    required this.appointmentId,
    required this.familyId,
    required this.hospitalId,
    required this.dateString,
    required this.timeSlot,
    required this.status,
    this.patientName = '',
    this.symptoms = '',
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> data) {
    return AppointmentModel(
      appointmentId: data['id'] ?? '',
      familyId: data['family_id'] ?? '',
      hospitalId: data['hospital_id'] ?? '',
      dateString: data['date_string'] ?? '',
      timeSlot: data['time_slot'] ?? '',
      status: data['status'] ?? 'pending',
      patientName: data['patient_name'] ?? '',
      symptoms: data['symptoms'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'family_id': familyId,
      'hospital_id': hospitalId,
      'date_string': dateString,
      'time_slot': timeSlot,
      'status': status,
      'patient_name': patientName,
      'symptoms': symptoms,
    };
    if (appointmentId.isNotEmpty) {
      map['id'] = appointmentId;
    }
    return map;
  }

  AppointmentModel copyWith({
    String? appointmentId,
    String? familyId,
    String? hospitalId,
    String? dateString,
    String? timeSlot,
    String? status,
    String? patientName,
    String? symptoms,
  }) {
    return AppointmentModel(
      appointmentId: appointmentId ?? this.appointmentId,
      familyId: familyId ?? this.familyId,
      hospitalId: hospitalId ?? this.hospitalId,
      dateString: dateString ?? this.dateString,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      patientName: patientName ?? this.patientName,
      symptoms: symptoms ?? this.symptoms,
    );
  }
}
