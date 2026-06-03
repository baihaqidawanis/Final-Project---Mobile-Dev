import 'package:flutter/foundation.dart';
import '../models/appointment_model.dart';

class MockHospitalService {
  // Returns a list of 3-4 appointments for a given date
  Future<List<AppointmentModel>> getAppointmentsForDate(String dateString) async {
    // Simulate minor network delay
    await Future.delayed(const Duration(milliseconds: 600));
    
    return [
      AppointmentModel(
        appointmentId: 'mock-appt-1',
        familyId: 'family-mock-id',
        hospitalId: 'hospital-mock-id',
        dateString: dateString,
        timeSlot: '09:00',
        status: 'booked',
      ),
      AppointmentModel(
        appointmentId: 'mock-appt-2',
        familyId: 'family-mock-id',
        hospitalId: 'hospital-mock-id',
        dateString: dateString,
        timeSlot: '11:00',
        status: 'booked',
      ),
      AppointmentModel(
        appointmentId: 'mock-appt-3',
        familyId: 'family-mock-id',
        hospitalId: 'hospital-mock-id',
        dateString: dateString,
        timeSlot: '14:00',
        status: 'booked',
      ),
      AppointmentModel(
        appointmentId: 'mock-appt-4',
        familyId: 'family-mock-id',
        hospitalId: 'hospital-mock-id',
        dateString: dateString,
        timeSlot: '16:00',
        status: 'booked',
      ),
    ];
  }

  // Simulates booking and prints payload
  Future<void> bookAppointment(AppointmentModel appointment) async {
    // Simulate minor network delay
    await Future.delayed(const Duration(milliseconds: 400));
    
    // Print the payload for verification
    debugPrint('-----------------------------------------');
    debugPrint('[MockHospitalService] Booking Appointment:');
    debugPrint('Appointment ID: ${appointment.appointmentId}');
    debugPrint('Payload (toMap): ${appointment.toMap()}');
    debugPrint('-----------------------------------------');
  }
}
