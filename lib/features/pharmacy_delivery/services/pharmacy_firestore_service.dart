import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pharmacy_profile_model.dart';
import '../models/medicine_model.dart';
import '../models/pharmacy_order_model.dart';

class PrescriptionUploadResult {
  final String url;
  final String path;

  const PrescriptionUploadResult({required this.url, required this.path});
}

class PharmacyFirestoreService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ── Pharmacies ───────────────────────────────────────────────────────────

  Stream<List<PharmacyProfileModel>> getPharmacies() {
    return _supabase
        .from('pharmacies')
        .stream(primaryKey: ['id'])
        .map((list) => list.map(PharmacyProfileModel.fromMap).toList());
  }

  Future<Map<String, dynamic>?> getPharmacyProfile(String uid) async {
    try {
      return await _supabase
          .from('pharmacies')
          .select()
          .eq('id', uid)
          .maybeSingle();
    } catch (e) {
      throw Exception('Failed to get pharmacy profile: $e');
    }
  }

  Future<void> updatePharmacyProfile(
    String uid,
    Map<String, dynamic> fields,
  ) async {
    try {
      final mappedFields = <String, dynamic>{};
      fields.forEach((key, value) {
        if (key == 'openHours') {
          mappedFields['open_hours'] = value;
        } else if (key == 'photoUrl') {
          mappedFields['photo_url'] = value;
        } else if (key == 'isOpen') {
          mappedFields['is_open'] = value;
        } else if (key == 'totalReviews') {
          mappedFields['total_reviews'] = value;
        } else {
          mappedFields[key] = value;
        }
      });

      await _supabase
          .from('pharmacies')
          .update(mappedFields)
          .eq('id', uid);
    } catch (e) {
      throw Exception('Failed to update pharmacy profile: $e');
    }
  }

  // ── Medicines ────────────────────────────────────────────────────────────

  Stream<List<MedicineModel>> getMedicinesByPharmacy(String pharmacyId) {
    return _supabase
        .from('medicines')
        .stream(primaryKey: ['id'])
        .eq('pharmacy_id', pharmacyId)
        .map(
          (list) => list
              .map(MedicineModel.fromMap)
              .where((m) => m.isAvailable)
              .toList(),
        );
  }

  Stream<List<MedicineModel>> getAllMedicinesByPharmacy(String pharmacyId) {
    return _supabase
        .from('medicines')
        .stream(primaryKey: ['id'])
        .eq('pharmacy_id', pharmacyId)
        .map((list) => list.map(MedicineModel.fromMap).toList());
  }

  Future<void> addMedicine(MedicineModel medicine) async {
    try {
      await _supabase.from('medicines').insert(medicine.toMap());
    } catch (e) {
      throw Exception('Failed to add medicine: $e');
    }
  }

  Future<void> updateMedicine(
    String medicineId,
    Map<String, dynamic> fields,
  ) async {
    try {
      final mappedFields = <String, dynamic>{};
      fields.forEach((key, value) {
        if (key == 'pharmacyId') {
          mappedFields['pharmacy_id'] = value;
        } else if (key == 'isAvailable') {
          mappedFields['is_available'] = value;
        } else {
          mappedFields[key] = value;
        }
      });
      await _supabase
          .from('medicines')
          .update(mappedFields)
          .eq('id', medicineId);
    } catch (e) {
      throw Exception('Failed to update medicine: $e');
    }
  }

  Future<void> deleteMedicine(String medicineId) async {
    try {
      await _supabase
          .from('medicines')
          .delete()
          .eq('id', medicineId);
    } catch (e) {
      throw Exception('Failed to delete medicine: $e');
    }
  }

  // ── Orders ───────────────────────────────────────────────────────────────

  Future<PrescriptionUploadResult> uploadPrescriptionImage({
    required String userId,
    required String pharmacyId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    try {
      final safeFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final path = '$pharmacyId/$userId/${DateTime.now().millisecondsSinceEpoch}_$safeFileName';

      await _supabase.storage.from('prescriptions').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );

      final url = _supabase.storage.from('prescriptions').getPublicUrl(path);
      return PrescriptionUploadResult(url: url, path: path);
    } catch (e) {
      throw Exception('Failed to upload prescription image: $e');
    }
  }

  Future<void> createOrder(PharmacyOrderModel order) async {
    try {
      await _supabase.from('pharmacy_orders').insert(order.toMap());
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  Stream<List<PharmacyOrderModel>> getOrdersByUser(String userId) {
    return _supabase
        .from('pharmacy_orders')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((list) {
          final orders = list.map(PharmacyOrderModel.fromMap).toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  Stream<List<PharmacyOrderModel>> getOrdersByPharmacy(String pharmacyId) {
    return _supabase
        .from('pharmacy_orders')
        .stream(primaryKey: ['id'])
        .eq('pharmacy_id', pharmacyId)
        .map((list) {
          final orders = list.map(PharmacyOrderModel.fromMap).toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  Future<void> updateOrderStatus(
    String orderId,
    PharmacyOrderStatus status,
  ) async {
    try {
      await _supabase
          .from('pharmacy_orders')
          .update({
            'status': PharmacyOrderModel.statusToString(status),
          })
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Customer confirms receipt and optionally leaves rating + review.
  Future<void> confirmDelivery(
    String orderId,
    String pharmacyId, {
    double? rating,
    String? review,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': PharmacyOrderModel.statusToString(
          PharmacyOrderStatus.delivered,
        ),
      };
      if (rating != null) updateData['rating'] = rating;
      if (review != null && review.isNotEmpty) updateData['review'] = review;

      // Update order status
      await _supabase
          .from('pharmacy_orders')
          .update(updateData)
          .eq('id', orderId);

      // If rating is provided, update aggregate rating
      if (rating != null) {
        final pharmacyData = await _supabase
            .from('pharmacies')
            .select()
            .eq('id', pharmacyId)
            .maybeSingle();

        if (pharmacyData != null) {
          final currentRating = (pharmacyData['rating'] ?? 0.0).toDouble();
          final currentTotal = (pharmacyData['total_reviews'] ?? 0) as int;
          final newTotal = currentTotal + 1;
          final newRating = (currentRating * currentTotal + rating) / newTotal;

          await _supabase.from('pharmacies').update({
            'rating': double.parse(newRating.toStringAsFixed(1)),
            'total_reviews': newTotal,
          }).eq('id', pharmacyId);
        }
      }
    } catch (e) {
      throw Exception('Failed to confirm delivery: $e');
    }
  }
}
