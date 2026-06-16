import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/supabase_storage_service.dart';
import '../models/pharmacy_profile_model.dart';
import '../models/medicine_model.dart';
import '../models/pharmacy_order_model.dart';

class PrescriptionUploadResult {
  final String url;
  final String path;

  const PrescriptionUploadResult({required this.url, required this.path});
}

class PharmacyFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _notif = NotificationService();

  CollectionReference<Map<String, dynamic>> get _pharmacies =>
      _db.collection('pharmacies');
  CollectionReference<Map<String, dynamic>> get _medicines =>
      _db.collection('medicines');
  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('pharmacy_orders');

  // ── Pharmacies ───────────────────────────────────────────────────────────

  Stream<List<PharmacyProfileModel>> getPharmacies() {
    return _pharmacies.snapshots().map(
      (snap) => snap.docs.map(PharmacyProfileModel.fromFirestore).toList(),
    );
  }

  Future<Map<String, dynamic>?> getPharmacyProfile(String uid) async {
    final doc = await _pharmacies.doc(uid).get();
    return doc.data();
  }

  Future<void> updatePharmacyProfile(
    String uid,
    Map<String, dynamic> fields,
  ) async {
    await _pharmacies.doc(uid).set(fields, SetOptions(merge: true));
  }

  // ── Medicines ────────────────────────────────────────────────────────────

  Stream<List<MedicineModel>> getMedicinesByPharmacy(String pharmacyId) {
    return _medicines
        .where('pharmacyId', isEqualTo: pharmacyId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(MedicineModel.fromFirestore)
              .where((m) => m.isAvailable)
              .toList(),
        );
  }

  Stream<List<MedicineModel>> getAllMedicinesByPharmacy(String pharmacyId) {
    return _medicines
        .where('pharmacyId', isEqualTo: pharmacyId)
        .snapshots()
        .map((snap) => snap.docs.map(MedicineModel.fromFirestore).toList());
  }

  Future<void> addMedicine(MedicineModel medicine) async {
    await _medicines.add(medicine.toMap());
  }

  Future<void> updateMedicine(
    String medicineId,
    Map<String, dynamic> fields,
  ) async {
    await _medicines.doc(medicineId).update(fields);
  }

  Future<void> deleteMedicine(String medicineId) async {
    await _medicines.doc(medicineId).delete();
  }

  // ── Orders ───────────────────────────────────────────────────────────────

  Future<PrescriptionUploadResult> uploadPrescriptionImage({
    required String userId,
    required String pharmacyId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final safeFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path =
        'pharmacy_prescriptions/$pharmacyId/$userId/${DateTime.now().millisecondsSinceEpoch}_$safeFileName';
    
    final String url = await SupabaseStorageService().uploadBytes(
      bytes: bytes,
      filePath: path,
      contentType: contentType,
    );
    
    return PrescriptionUploadResult(url: url, path: path);
  }

  Future<void> createOrder(PharmacyOrderModel order) async {
    await _orders.add(order.toMap());
    // Notify pharmacy (mitra) about new incoming order
    _notif.sendNotificationToUser(
      targetUid: order.pharmacyId,
      title: 'Pesanan Baru Masuk!',
      body:
          '${order.userName} memesan ${order.items.length} item obat',
      data: {'type': 'pharmacy_new_order'},
    );
  }

  Future<int> getPendingOrderCount(String pharmacyId) async {
    final snap = await _orders
        .where('pharmacyId', isEqualTo: pharmacyId)
        .where('status', isEqualTo: 'pending')
        .get();
    return snap.size;
  }

  Future<List<PharmacyOrderModel>> getActiveOrdersForUser(String userId) async {
    final snap = await _orders
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['accepted', 'shipped'])
        .get();
    final orders = snap.docs.map(PharmacyOrderModel.fromFirestore).toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  Stream<List<PharmacyOrderModel>> getOrdersByUser(String userId) {
    return _orders.where('userId', isEqualTo: userId).snapshots().map((snap) {
      final orders = snap.docs.map(PharmacyOrderModel.fromFirestore).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Stream<List<PharmacyOrderModel>> getOrdersByPharmacy(String pharmacyId) {
    return _orders.where('pharmacyId', isEqualTo: pharmacyId).snapshots().map((
      snap,
    ) {
      final orders = snap.docs.map(PharmacyOrderModel.fromFirestore).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Future<void> updateOrderStatus(
    String orderId,
    PharmacyOrderStatus status, {
    PharmacyOrderModel? order,
  }) async {
    await _orders.doc(orderId).update({
      'status': PharmacyOrderModel.statusToString(status),
    });

    if (order == null) return;

    switch (status) {
      case PharmacyOrderStatus.accepted:
        _notif.sendNotificationToUser(
          targetUid: order.userId,
          title: 'Pesanan Dikonfirmasi!',
          body:
              '${order.pharmacyName} menerima pesananmu dan sedang mengemas',
          data: {'type': 'pharmacy_order_accepted', 'orderId': orderId},
        );
      case PharmacyOrderStatus.shipped:
        _notif.sendNotificationToUser(
          targetUid: order.userId,
          title: 'Pesanan Sedang Dikirim!',
          body:
              'Pesananmu dari ${order.pharmacyName} sedang dalam perjalanan',
          data: {'type': 'pharmacy_order_shipped', 'orderId': orderId},
        );
      case PharmacyOrderStatus.cancelled:
        _notif.sendNotificationToUser(
          targetUid: order.userId,
          title: 'Pesanan Dibatalkan',
          body:
              'Maaf, pesananmu dari ${order.pharmacyName} tidak dapat diproses',
          data: {'type': 'pharmacy_order_cancelled', 'orderId': orderId},
        );
      default:
        break;
    }
  }

  // Customer confirms receipt and optionally leaves rating + review.
  // Updates pharmacy aggregate rating atomically via transaction.
  Future<void> confirmDelivery(
    String orderId,
    String pharmacyId, {
    double? rating,
    String? review,
    String? userName,
  }) async {
    final orderRef = _orders.doc(orderId);
    final updateData = <String, dynamic>{
      'status': PharmacyOrderModel.statusToString(
        PharmacyOrderStatus.delivered,
      ),
    };
    if (rating != null) updateData['rating'] = rating;
    if (review != null && review.isNotEmpty) updateData['review'] = review;

    await _db.runTransaction((txn) async {
      // Firestore rule: ALL reads must happen before any write.
      Map<String, dynamic>? pharmacyData;
      final pharmacyRef = _pharmacies.doc(pharmacyId);
      if (rating != null) {
        final snap = await txn.get(pharmacyRef);
        if (snap.exists) pharmacyData = snap.data();
      }

      // Writes come after all reads.
      txn.update(orderRef, updateData);
      if (rating != null && pharmacyData != null) {
        final currentRating = (pharmacyData['rating'] ?? 0.0).toDouble();
        final currentTotal = (pharmacyData['totalReviews'] ?? 0) as int;
        final newTotal = currentTotal + 1;
        final newRating = (currentRating * currentTotal + rating) / newTotal;
        txn.update(pharmacyRef, {
          'rating': double.parse(newRating.toStringAsFixed(1)),
          'totalReviews': newTotal,
        });
      }
    });

    // Notify pharmacy (mitra) that customer confirmed receipt
    _notif.sendNotificationToUser(
      targetUid: pharmacyId,
      title: 'Pesanan Telah Diterima!',
      body:
          '${userName ?? 'Pelanggan'} mengkonfirmasi penerimaan pesanan',
      data: {'type': 'pharmacy_order_delivered', 'orderId': orderId},
    );
  }
}
