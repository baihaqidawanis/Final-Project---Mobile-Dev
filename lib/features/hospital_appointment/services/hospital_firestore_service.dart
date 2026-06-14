import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class HospitalFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _appointmentsRef => _firestore.collection('appointments');

  // Create: Logic for a family to claim/book an available time slot
  Future<String> createAppointment(AppointmentModel appointment) async {
    try {
      final docRef = await _appointmentsRef.add(appointment.toMap());
      
      // Trigger background FCM push notification targeting 'hospital_admin' topic
      final createdAppointment = appointment.copyWith(appointmentId: docRef.id);
      _sendFCMNotification(createdAppointment);
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create appointment: $e');
    }
  }

  // Send push notification targeting 'hospital_admin' topic
  Future<void> _sendFCMNotification(AppointmentModel appointment) async {
    try {
      final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=YOUR_FCM_SERVER_KEY_PLACEHOLDER',
        },
        body: jsonEncode({
          'to': '/topics/hospital_admin',
          'notification': {
            'title': 'New Appointment Booked',
            'body': 'Slot: ${appointment.timeSlot} on Date: ${appointment.dateString}',
          },
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'appointmentId': appointment.appointmentId,
          },
        }),
      );
      if (response.statusCode != 200) {
        debugPrint('[FCM] Notification request failed: ${response.body}');
      } else {
        debugPrint('[FCM] Topic notification triggered successfully.');
      }
    } catch (e) {
      debugPrint('[FCM] Error sending topic notification: $e');
    }
  }

  // Read: Fetch all appointments for a specific date (general read)
  Stream<List<AppointmentModel>> getAppointmentsForDate(String dateString) {
    return _appointmentsRef
        .where('dateString', isEqualTo: dateString)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromFirestore(doc))
            .toList());
  }

  // Read: Logic for families to view their itineraries
  Stream<List<AppointmentModel>> getFamilyAppointments(String familyId) {
    return _appointmentsRef
        .where('familyId', isEqualTo: familyId)
        .orderBy('dateString')
        .orderBy('timeSlot')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromFirestore(doc))
            .toList());
  }

  // Read: Logic for hospital admins to read chronological daily agendas (Admin view)
  Stream<List<AppointmentModel>> getHospitalDailyAgenda(String hospitalId, String dateString) {
    return _appointmentsRef
        .where('hospitalId', isEqualTo: hospitalId)
        .where('dateString', isEqualTo: dateString)
        .orderBy('timeSlot')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromFirestore(doc))
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

  // Delete: Logic for families or admins to delete/cancel appointments
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _appointmentsRef.doc(appointmentId).delete();
    } catch (e) {
      throw Exception('Failed to cancel appointment: $e');
    }
  }
}
