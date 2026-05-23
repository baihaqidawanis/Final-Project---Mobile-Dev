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

  // ════════════════════════════════════════════════════════════════════════
  //  SEED — Add dummy caregiver data for testing (call once)
  // ════════════════════════════════════════════════════════════════════════
  Future<void> seedDummyCaregivers() async {
    final existing = await _caregivers.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final dummies = [
      {
        'name': 'Siti Rahayu',
        'specialization': 'Elderly Care',
        'pricePerHour': 75000.0,
        'rating': 4.9,
        'totalReviews': 128,
        'photoUrl': '',
        'bio': 'Berpengalaman 5 tahun merawat lansia. Sabar dan telaten.',
        'area': 'Jakarta Selatan',
        'isAvailable': true,
      },
      {
        'name': 'Budi Santoso',
        'specialization': 'Post-Surgery Care',
        'pricePerHour': 90000.0,
        'rating': 4.7,
        'totalReviews': 85,
        'photoUrl': '',
        'bio': 'Perawat bersertifikat dengan pengalaman perawatan pasca operasi.',
        'area': 'Bekasi',
        'isAvailable': true,
      },
      {
        'name': 'Dewi Kusuma',
        'specialization': 'Child Care',
        'pricePerHour': 65000.0,
        'rating': 4.8,
        'totalReviews': 210,
        'photoUrl': '',
        'bio': 'Spesialis perawatan anak, berpengalaman dengan anak berkebutuhan khusus.',
        'area': 'Depok',
        'isAvailable': true,
      },
      {
        'name': 'Ahmad Fauzi',
        'specialization': 'Physiotherapy',
        'pricePerHour': 120000.0,
        'rating': 4.6,
        'totalReviews': 64,
        'photoUrl': '',
        'bio': 'Fisioterapis bersertifikat, membantu pemulihan pasca stroke.',
        'area': 'Tangerang',
        'isAvailable': true,
      },
    ];

    final batch = _db.batch();
    for (final d in dummies) {
      batch.set(_caregivers.doc(), d);
    }
    await batch.commit();
  }
}
