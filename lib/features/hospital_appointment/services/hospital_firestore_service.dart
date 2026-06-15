import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/notification_service.dart';
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

      // Trigger targeted notification to the specific hospital
      NotificationService().sendNotificationToUser(
        targetUid: appointment.hospitalId,
        title: 'Janji Temu Baru 🏥',
        body: 'Pasien ${appointment.patientName} menjadwalkan kunjungan pada ${appointment.dateString} pukul ${appointment.timeSlot}',
        data: {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'type': 'hospital_appointment',
          'appointmentId': docRef.id,
        },
      );
      
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
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => AppointmentModel.fromFirestore(doc))
              .toList();
          // Sort in-memory: sort by dateString, then by timeSlot
          list.sort((a, b) {
            final dateCompare = a.dateString.compareTo(b.dateString);
            if (dateCompare != 0) return dateCompare;
            return a.timeSlot.compareTo(b.timeSlot);
          });
          return list;
        });
  }

  // Read: Logic for hospital admins to read chronological daily agendas (Admin view)
  Stream<List<AppointmentModel>> getHospitalDailyAgenda(String hospitalId, String dateString) {
    return _appointmentsRef
        .where('hospitalId', isEqualTo: hospitalId)
        .where('dateString', isEqualTo: dateString)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => AppointmentModel.fromFirestore(doc))
              .toList();
          // Sort in-memory by timeSlot
          list.sort((a, b) => a.timeSlot.compareTo(b.timeSlot));
          return list;
        });
  }

  // Update: Logic for hospital admins to modify appointment states
  Future<void> updateAppointmentStatus(String appointmentId, String newStatus, {String statusReason = ''}) async {
    try {
      // 1. Fetch current appointment details
      final docSnapshot = await _appointmentsRef.doc(appointmentId).get();
      if (!docSnapshot.exists) {
        throw Exception('Appointment not found');
      }
      final appointment = AppointmentModel.fromFirestore(docSnapshot);

      // 2. Update status and statusReason in Firestore
      await _appointmentsRef.doc(appointmentId).update({
        'status': newStatus,
        'statusReason': statusReason,
      });

      // 3. Send push notification to the patient if it is not a walk-in (offline)
      if (appointment.familyId.isNotEmpty && appointment.familyId != 'offline') {
        // Fetch hospital name
        String hospitalName = 'Rumah Sakit';
        try {
          final hospitalDoc = await _firestore.collection('users').doc(appointment.hospitalId).get();
          if (hospitalDoc.exists) {
            final data = hospitalDoc.data();
            if (data != null && data['name'] != null) {
              hospitalName = data['name'];
            }
          }
        } catch (_) {}

        String title = 'Pembaruan Janji Temu 🏥';
        String body = 'Status janji temu Anda di $hospitalName telah diperbarui menjadi ${newStatus.toUpperCase()}.';

        if (newStatus.toLowerCase() == 'delayed') {
          title = 'Janji Temu Ditunda ⏳';
          body = '$hospitalName menunda janji temu Anda pada ${appointment.dateString} pukul ${appointment.timeSlot}. Alasan: $statusReason';
        } else if (newStatus.toLowerCase() == 'cancelled') {
          title = 'Janji Temu Dibatalkan ❌';
          body = '$hospitalName membatalkan janji temu Anda pada ${appointment.dateString} pukul ${appointment.timeSlot}. Alasan: $statusReason';
        } else if (newStatus.toLowerCase() == 'approved') {
          title = 'Janji Temu Disetujui  ';
          body = '$hospitalName telah menyetujui janji temu Anda pada ${appointment.dateString} pukul ${appointment.timeSlot}.';
        } else if (newStatus.toLowerCase() == 'completed') {
          title = 'Janji Temu Selesai ';
          body = 'Janji temu Anda di $hospitalName pada ${appointment.dateString} telah selesai.';
        }

        NotificationService().sendNotificationToUser(
          targetUid: appointment.familyId,
          title: title,
          body: body,
          data: {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'type': 'hospital_appointment',
            'appointmentId': appointmentId,
          },
        );
      }
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
