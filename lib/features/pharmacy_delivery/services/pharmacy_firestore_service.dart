import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pharmacy_profile_model.dart';
import '../models/medicine_model.dart';
import '../models/pharmacy_order_model.dart';

class PharmacyFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _pharmacies =>
      _db.collection('pharmacies');
  CollectionReference<Map<String, dynamic>> get _medicines =>
      _db.collection('medicines');
  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('pharmacy_orders');

  // ── Pharmacies ───────────────────────────────────────────────────────────

  Stream<List<PharmacyProfileModel>> getPharmacies() {
    return _pharmacies.snapshots().map((snap) =>
        snap.docs.map(PharmacyProfileModel.fromFirestore).toList());
  }

  Future<Map<String, dynamic>?> getPharmacyProfile(String uid) async {
    final doc = await _pharmacies.doc(uid).get();
    return doc.data();
  }

  Future<void> updatePharmacyProfile(
      String uid, Map<String, dynamic> fields) async {
    await _pharmacies.doc(uid).set(fields, SetOptions(merge: true));
  }

  // ── Medicines ────────────────────────────────────────────────────────────

  Stream<List<MedicineModel>> getMedicinesByPharmacy(String pharmacyId) {
    return _medicines
        .where('pharmacyId', isEqualTo: pharmacyId)
        .snapshots()
        .map((snap) => snap.docs
            .map(MedicineModel.fromFirestore)
            .where((m) => m.isAvailable)
            .toList());
  }

  Stream<List<MedicineModel>> getAllMedicinesByPharmacy(String pharmacyId) {
    return _medicines
        .where('pharmacyId', isEqualTo: pharmacyId)
        .snapshots()
        .map((snap) =>
            snap.docs.map(MedicineModel.fromFirestore).toList());
  }

  Future<void> addMedicine(MedicineModel medicine) async {
    await _medicines.add(medicine.toMap());
  }

  Future<void> updateMedicine(
      String medicineId, Map<String, dynamic> fields) async {
    await _medicines.doc(medicineId).update(fields);
  }

  Future<void> deleteMedicine(String medicineId) async {
    await _medicines.doc(medicineId).delete();
  }

  // ── Orders ───────────────────────────────────────────────────────────────

  Future<void> createOrder(PharmacyOrderModel order) async {
    await _orders.add(order.toMap());
  }

  Stream<List<PharmacyOrderModel>> getOrdersByUser(String userId) {
    return _orders
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final orders =
          snap.docs.map(PharmacyOrderModel.fromFirestore).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Stream<List<PharmacyOrderModel>> getOrdersByPharmacy(String pharmacyId) {
    return _orders
        .where('pharmacyId', isEqualTo: pharmacyId)
        .snapshots()
        .map((snap) {
      final orders =
          snap.docs.map(PharmacyOrderModel.fromFirestore).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Future<void> updateOrderStatus(
      String orderId, PharmacyOrderStatus status) async {
    await _orders.doc(orderId).update({
      'status': PharmacyOrderModel.statusToString(status),
    });
  }
}
