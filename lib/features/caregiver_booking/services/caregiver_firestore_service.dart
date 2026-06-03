import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/caregiver_profile_model.dart';

class CaregiverFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Public getter for direct Firestore access
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
  //  READ — Get all available caregivers (real-time stream)
  // ════════════════════════════════════════════════════════════════════════
  Stream<List<CaregiverProfileModel>> getCaregivers() {
    return _caregivers
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(CaregiverProfileModel.fromFirestore).toList());
  }

  // ════════════════════════════════════════════════════════════════════════
  //  READ — Caregiver profile as real-time stream (fixes dashboard live-reload)
  // ════════════════════════════════════════════════════════════════════════
  Stream<Map<String, dynamic>?> getCaregiverProfileStream(String uid) {
    if (uid.isEmpty) return Stream.value(null);
    return _caregivers
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  // ════════════════════════════════════════════════════════════════════════
  //  READ — Family: watch all their own bookings (for My Bookings screen)
  // ════════════════════════════════════════════════════════════════════════
  Stream<List<BookingModel>> getBookingsByFamily(String familyId) {
    return _bookings
        .where('familyId', isEqualTo: familyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(BookingModel.fromFirestore).toList());
  }

  // ════════════════════════════════════════════════════════════════════════
  //  READ — Caregiver: watch all incoming requests (real-time)
  // ════════════════════════════════════════════════════════════════════════
  Stream<List<BookingModel>> getBookingsByCaregiver(String caregiverId) {
    return _bookings
        .where('caregiverId', isEqualTo: caregiverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(BookingModel.fromFirestore).toList());
  }

  // ════════════════════════════════════════════════════════════════════════
  //  READ — Caregiver: completed & cancelled bookings (for History screen)
  // ════════════════════════════════════════════════════════════════════════
  Stream<List<BookingModel>> getCompletedBookingsByCaregiver(String caregiverId) {
    return _bookings
        .where('caregiverId', isEqualTo: caregiverId)
        .where('status', whereIn: ['completed', 'cancelled'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(BookingModel.fromFirestore).toList());
  }

  // ════════════════════════════════════════════════════════════════════════
  //  READ — Caregiver: only pending + accepted (active queue)
  // ════════════════════════════════════════════════════════════════════════
  Stream<List<BookingModel>> getActiveBookingsByCaregiver(String caregiverId) {
    return _bookings
        .where('caregiverId', isEqualTo: caregiverId)
        .where('status', whereIn: ['pending', 'accepted'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(BookingModel.fromFirestore).toList());
  }

  // ════════════════════════════════════════════════════════════════════════
  //  UPDATE — Caregiver: accept or decline a booking
  // ════════════════════════════════════════════════════════════════════════
  Future<void> updateBookingStatus(
      String bookingId, BookingStatus status) async {
    await _bookings.doc(bookingId).update({
      'status': BookingModel.statusToString(status),
    });
  }

  // ════════════════════════════════════════════════════════════════════════
  //  UPDATE — Caregiver: mark complete + write clinical log note (per PRD)
  // ════════════════════════════════════════════════════════════════════════
  Future<void> completeBookingWithNote(
      String bookingId, String clinicalNote) async {
    await _bookings.doc(bookingId).update({
      'status': BookingModel.statusToString(BookingStatus.completed),
      'clinicalNote': clinicalNote.trim(),
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // ════════════════════════════════════════════════════════════════════════
  //  DELETE — Family: cancel a pending booking (sets status to cancelled)
  // ════════════════════════════════════════════════════════════════════════
  Future<void> cancelBooking(String bookingId) async {
    await _bookings.doc(bookingId).update({
      'status': BookingModel.statusToString(BookingStatus.cancelled),
    });
  }

  // ════════════════════════════════════════════════════════════════════════
  //  UPDATE — Caregiver: edit their own public profile
  // ════════════════════════════════════════════════════════════════════════
  Future<void> updateCaregiverProfile(
      String uid, Map<String, dynamic> updatedFields) async {
    await _caregivers.doc(uid).update(updatedFields);
  }

  // NOTE: No seed data — caregivers appear when they register via MitraRegisterScreen
}
