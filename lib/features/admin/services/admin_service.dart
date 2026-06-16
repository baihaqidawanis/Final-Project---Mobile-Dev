import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collections ───────────────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _caregivers => _db.collection('caregivers');
  CollectionReference<Map<String, dynamic>> get _bookings => _db.collection('bookings');
  CollectionReference<Map<String, dynamic>> get _reports => _db.collection('reports');
  CollectionReference<Map<String, dynamic>> get _reviews => _db.collection('reviews');

  // ════════════════════════════════════════════════════════════════════════
  //  USER MANAGEMENT
  // ════════════════════════════════════════════════════════════════════════

  Stream<QuerySnapshot<Map<String, dynamic>>> getUsersStream() =>
      // Role disimpan sebagai 'family' di user_model.dart
      _users.where('role', isEqualTo: 'family').snapshots();

  Future<void> blockUser(String uid, bool block) async {
    await _users.doc(uid).update({'isBlocked': block});
  }

  Future<void> deleteUser(String uid) async {
    await _users.doc(uid).delete();
  }

  // ════════════════════════════════════════════════════════════════════════
  //  CAREGIVER MANAGEMENT
  // ════════════════════════════════════════════════════════════════════════

  Stream<QuerySnapshot<Map<String, dynamic>>> getCaregiversStream() =>
      _caregivers.snapshots();

  Future<void> blockCaregiver(String uid, bool block) async {
    // isBlocked flag + set isAvailable to false when blocked
    await _caregivers.doc(uid).update({
      'isBlocked': block,
      if (block) 'isAvailable': false,
    });
  }

  Future<void> deleteCaregiver(String uid) async {
    await _caregivers.doc(uid).delete();
  }

  // ════════════════════════════════════════════════════════════════════════
  //  BOOKING MANAGEMENT
  // ════════════════════════════════════════════════════════════════════════

  Future<void> forceCancelBooking(String bookingId, String adminNote) async {
    await _bookings.doc(bookingId).update({
      'status': 'cancelled',
      'adminNote': adminNote,
      'cancelledByAdmin': true,
    });
  }

  // ════════════════════════════════════════════════════════════════════════
  //  REPORTS
  // ════════════════════════════════════════════════════════════════════════

  /// Submit a report from user or mitra
  Future<void> submitReport({
    required String reporterId,
    required String reporterName,
    required String reporterRole, // 'user' or 'caregiver'
    required String targetId,
    required String targetName,
    required String targetType, // 'caregiver', 'user', 'booking'
    required String reason,
    required String description,
    String? bookingId,
  }) async {
    await _reports.add({
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reporterRole': reporterRole,
      'targetId': targetId,
      'targetName': targetName,
      'targetType': targetType,
      'reason': reason,
      'description': description,
      'bookingId': bookingId,
      'status': 'pending', // 'pending' | 'reviewed' | 'resolved' | 'dismissed'
      'adminNote': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getReportsStream() =>
      _reports.orderBy('createdAt', descending: true).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> getPendingReportsStream() =>
      _reports
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots();

  Future<void> updateReportStatus(
    String reportId,
    String status, // 'reviewed' | 'resolved' | 'dismissed'
    String adminNote,
  ) async {
    await _reports.doc(reportId).update({
      'status': status,
      'adminNote': adminNote,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  // ════════════════════════════════════════════════════════════════════════
  //  REVIEWS
  // ════════════════════════════════════════════════════════════════════════

  /// User submits a review after a completed booking
  Future<void> submitReview({
    required String bookingId,
    required String caregiverId,
    required String caregiverName,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
  }) async {
    // Save review document
    await _reviews.doc(bookingId).set({
      'bookingId': bookingId,
      'caregiverId': caregiverId,
      'caregiverName': caregiverName,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Recalculate caregiver's average rating
    final snap = await _reviews
        .where('caregiverId', isEqualTo: caregiverId)
        .get();

    if (snap.docs.isNotEmpty) {
      final ratings = snap.docs
          .map((d) => (d.data()['rating'] as num).toDouble())
          .toList();
      final avg = ratings.reduce((a, b) => a + b) / ratings.length;
      await _caregivers.doc(caregiverId).update({
        'rating': double.parse(avg.toStringAsFixed(1)),
        'totalReviews': ratings.length,
      });
    }
  }

  /// Check if a user already left a review for a booking
  Future<bool> hasReview(String bookingId) async {
    final doc = await _reviews.doc(bookingId).get();
    return doc.exists;
  }

  /// Get all reviews for a caregiver
  Stream<QuerySnapshot<Map<String, dynamic>>> getCaregiverReviews(String caregiverId) =>
      _reviews
          .where('caregiverId', isEqualTo: caregiverId)
          .orderBy('createdAt', descending: true)
          .snapshots();
}
