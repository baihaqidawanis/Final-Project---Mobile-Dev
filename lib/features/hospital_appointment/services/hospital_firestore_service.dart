import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class HospitalFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _appointmentsRef => _firestore.collection('appointments');

  // Create: Logic for a family to claim an available time chip
  Future<String> createAppointment(AppointmentModel appointment) async {
    try {
      final docRef = await _appointmentsRef.add(appointment.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create appointment: $e');
    }
  }

  // Read: Logic for families to view their itineraries
  Stream<List<AppointmentModel>> getFamilyAppointments(String familyId) {
    return _appointmentsRef
        .where('familyId', isEqualTo: familyId)
        .orderBy('dateString')
        .orderBy('timeSlot')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Read: Logic for hospital admins to read chronological daily agendas
  Stream<List<AppointmentModel>> getHospitalDailyAgenda(String hospitalId, String dateString) {
    return _appointmentsRef
        .where('hospitalId', isEqualTo: hospitalId)
        .where('dateString', isEqualTo: dateString)
        .orderBy('timeSlot')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Update: Logic for hospital admins to modify appointment states
  Future<void> updateAppointmentStatus(String appointmentId, String newStatus) async {
    try {
      await _appointmentsRef.doc(appointmentId).update({'status': newStatus});
    } catch (e) {
      throw Exception('Failed to update appointment status: $e');
    }
  }

  // Delete: Logic for families to cancel appointments
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _appointmentsRef.doc(appointmentId).delete();
    } catch (e) {
      throw Exception('Failed to cancel appointment: $e');
    }
  }
}
