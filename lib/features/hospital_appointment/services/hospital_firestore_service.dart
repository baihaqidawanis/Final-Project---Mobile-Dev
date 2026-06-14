import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment_model.dart';

class HospitalFirestoreService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create: Logic for a family to claim/book an available time slot
  Future<String> createAppointment(AppointmentModel appointment) async {
    try {
      final res = await _supabase
          .from('appointments')
          .insert(appointment.toMap())
          .select()
          .single();
      
      return res['id'] as String;
    } catch (e) {
      throw Exception('Failed to create appointment: $e');
    }
  }

  // Read: Fetch all appointments for a specific date (general read)
  Stream<List<AppointmentModel>> getAppointmentsForDate(String dateString) {
    return _supabase
        .from('appointments')
        .stream(primaryKey: ['id'])
        .eq('date_string', dateString)
        .map((list) => list.map(AppointmentModel.fromMap).toList());
  }

  // Read: Logic for families to view their itineraries
  Stream<List<AppointmentModel>> getFamilyAppointments(String familyId) {
    return _supabase
        .from('appointments')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .map((list) {
          final items = list.map(AppointmentModel.fromMap).toList();
          items.sort((a, b) {
            final dateCompare = a.dateString.compareTo(b.dateString);
            if (dateCompare != 0) return dateCompare;
            return a.timeSlot.compareTo(b.timeSlot);
          });
          return items;
        });
  }

  // Read: Logic for hospital admins to read daily agendas
  Stream<List<AppointmentModel>> getHospitalDailyAgenda(String hospitalId, String dateString) {
    return _supabase
        .from('appointments')
        .stream(primaryKey: ['id'])
        .eq('hospital_id', hospitalId)
        .map((list) {
          final items = list
              .map(AppointmentModel.fromMap)
              .where((a) => a.dateString == dateString)
              .toList();
          items.sort((a, b) => a.timeSlot.compareTo(b.timeSlot));
          return items;
        });
  }

  // Update: Logic for hospital admins to modify appointment states
  Future<void> updateAppointmentStatus(String appointmentId, String newStatus) async {
    try {
      await _supabase
          .from('appointments')
          .update({'status': newStatus})
          .eq('id', appointmentId);
    } catch (e) {
      throw Exception('Failed to update appointment status: $e');
    }
  }

  // Delete: Logic for families or admins to delete/cancel appointments
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _supabase
          .from('appointments')
          .delete()
          .eq('id', appointmentId);
    } catch (e) {
      throw Exception('Failed to cancel appointment: $e');
    }
  }
}
