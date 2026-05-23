import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/caregiver_profile_model.dart';

class CaregiverFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Public getter for direct Firestore access (e.g. profile fetch)
  FirebaseFirestore get db => _db;

  // ── Collections ──────────────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('bookings');
  CollectionReference<Map<String, dynamic>> get _caregivers =>
      _db.collection('caregivers');

  // ════════════════════════════════════════════════════════════════════════
  //  CREATE — Family submits a new booking
  // ════════════════════════════════════════════════════════════════════════
  Future<void> createBooking(BookingModel booking) async {
    await _bookings.add(booking.toMap());
  }

  // ════════════════════════════════════════════════════════════════════════
  //  READ — Get all caregivers (stream for real-time updates)
  // ════════════════════════════════════════════════════════════════════════
  Stream<List<CaregiverProfileModel>> getCaregivers() {
    return _caregivers
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(CaregiverProfileModel.fromFirestore).toList());
  }

  // ════════════════════════════════════════════════════════════════════════
  //  READ — Family: watch their own bookings
  // ════════════════════════════════════════════════════════════════════════
  Stream<List<BookingModel>> getBookingsByFamily(String familyId) {
    return _bookings
        .where('familyId', isEqualTo: familyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(BookingModel.fromFirestore).toList());
  }

  // ════════════════════════════════════════════════════════════════════════
  //  READ — Caregiver: watch incoming requests
  // ════════════════════════════════════════════════════════════════════════
  Stream<List<BookingModel>> getBookingsByCaregiver(String caregiverId) {
    return _bookings
        .where('caregiverId', isEqualTo: caregiverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(BookingModel.fromFirestore).toList());
  }

  // ════════════════════════════════════════════════════════════════════════
  //  UPDATE — Caregiver: accept / decline / complete a booking
  // ════════════════════════════════════════════════════════════════════════
  Future<void> updateBookingStatus(
      String bookingId, BookingStatus status) async {
    await _bookings.doc(bookingId).update({
      'status': BookingModel.statusToString(status),
    });
  }

  // ════════════════════════════════════════════════════════════════════════
  //  DELETE — Family: cancel a pending booking
  // ════════════════════════════════════════════════════════════════════════
  Future<void> cancelBooking(String bookingId) async {
    await _bookings.doc(bookingId).update({
      'status': BookingModel.statusToString(BookingStatus.cancelled),
    });
  }

  Future<void> updateCaregiverProfile(
      String uid, Map<String, dynamic> updatedFields) async {
    await _caregivers.doc(uid).update(updatedFields);
  }

  // NOTE: No seed data — caregivers appear when they register via MitraRegisterScreen

}
