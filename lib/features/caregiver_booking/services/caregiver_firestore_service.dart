import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';
import '../models/caregiver_profile_model.dart';

class CaregiverFirestoreService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ── Create — Family submits a new booking
  Future<void> createBooking(BookingModel booking) async {
    try {
      await _supabase.from('bookings').insert(booking.toMap());
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  Future<bool> hasActiveBooking(String familyId, String caregiverId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('family_id', familyId)
          .eq('caregiver_id', caregiverId)
          .or('status.eq.pending,status.eq.accepted')
          .limit(1)
          .maybeSingle();
      return response != null;
    } catch (_) {
      return false;
    }
  }

  // ── READ — Get all available caregivers (real-time stream)
  Stream<List<CaregiverProfileModel>> getCaregivers() {
    return _supabase
        .from('caregivers')
        .stream(primaryKey: ['id'])
        .eq('is_available', true)
        .map((list) => list.map(CaregiverProfileModel.fromMap).toList());
  }

  // ── READ — Caregiver profile as real-time stream
  Stream<Map<String, dynamic>?> getCaregiverProfileStream(String uid) {
    if (uid.isEmpty) return Stream.value(null);
    return _supabase
        .from('caregivers')
        .stream(primaryKey: ['id'])
        .eq('id', uid)
        .map((list) => list.isNotEmpty ? list.first : null);
  }

  // ── READ — Family: watch all their own bookings
  Stream<List<BookingModel>> getBookingsByFamily(String familyId) {
    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .map((list) {
          final items = list.map(BookingModel.fromMap).toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  // ── READ — Caregiver: watch all incoming requests
  Stream<List<BookingModel>> getBookingsByCaregiver(String caregiverId) {
    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('caregiver_id', caregiverId)
        .map((list) {
          final items = list.map(BookingModel.fromMap).toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  // ── READ — Caregiver: completed & cancelled bookings
  Stream<List<BookingModel>> getCompletedBookingsByCaregiver(String caregiverId) {
    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('caregiver_id', caregiverId)
        .map((list) {
          final items = list
              .map(BookingModel.fromMap)
              .where((b) => b.status == BookingStatus.completed || b.status == BookingStatus.cancelled)
              .toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  // ── READ — Caregiver: only pending + accepted (active queue)
  Stream<List<BookingModel>> getActiveBookingsByCaregiver(String caregiverId) {
    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('caregiver_id', caregiverId)
        .map((list) {
          final items = list
              .map(BookingModel.fromMap)
              .where((b) => b.status == BookingStatus.pending || b.status == BookingStatus.accepted)
              .toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  // ── UPDATE — Caregiver: accept or decline a booking
  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    try {
      await _supabase
          .from('bookings')
          .update({'status': BookingModel.statusToString(status)})
          .eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  // ── UPDATE — Caregiver: mark complete + write clinical log note
  Future<void> completeBookingWithNote(String bookingId, String clinicalNote) async {
    try {
      await _supabase
          .from('bookings')
          .update({
            'status': BookingModel.statusToString(BookingStatus.completed),
            'clinical_note': clinicalNote.trim(),
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to complete booking: $e');
    }
  }

  // ── DELETE — Family: cancel a pending booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _supabase
          .from('bookings')
          .update({'status': BookingModel.statusToString(BookingStatus.cancelled)})
          .eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  // ── DELETE — Family: hard delete a booking from history
  Future<void> deleteBookingHistory(String bookingId) async {
    try {
      await _supabase
          .from('bookings')
          .delete()
          .eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to delete booking history: $e');
    }
  }

  // ── UPDATE — Caregiver: edit their own public profile
  Future<void> updateCaregiverProfile(String uid, Map<String, dynamic> updatedFields) async {
    try {
      final mappedFields = <String, dynamic>{};
      updatedFields.forEach((key, value) {
        if (key == 'pricePerHour') {
          mappedFields['price_per_hour'] = value;
        } else if (key == 'photoUrl') {
          mappedFields['photo_url'] = value;
        } else if (key == 'isAvailable') {
          mappedFields['is_available'] = value;
        } else if (key == 'totalReviews') {
          mappedFields['total_reviews'] = value;
        } else {
          mappedFields[key] = value;
        }
      });

      await _supabase
          .from('caregivers')
          .update(mappedFields)
          .eq('id', uid);
    } catch (e) {
      throw Exception('Failed to update caregiver profile: $e');
    }
  }

  // ── UPLOAD — Caregiver: upload profile photo via Base64 URI
  Future<String> uploadProfilePhoto({
    required String uid,
    required Uint8List bytes,
    required String contentType,
  }) async {
    try {
      final base64String = base64Encode(bytes);
      final dataUri = 'data:$contentType;base64,$base64String';

      await _supabase
          .from('caregivers')
          .update({'photo_url': dataUri})
          .eq('id', uid);
      return dataUri;
    } catch (e) {
      throw Exception('Failed to upload profile photo: $e');
    }
  }
}
