import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/booking_model.dart';
import '../services/caregiver_firestore_service.dart';
import '../widgets/status_badge.dart';

// ── TEMPORARY: Replace with FirebaseAuth.instance.currentUser!.uid ──────────
const String kDummyCaregiverId = 'caregiver_test_001';
// ────────────────────────────────────────────────────────────────────────────

class CaregiverDashboardScreen extends StatelessWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = CaregiverFirestoreService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Requests'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: service.getBookingsByCaregiver(kDummyCaregiverId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data ?? [];

          if (bookings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text(
                    'No requests yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Incoming bookings will appear here',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          // Separate pending from others
          final pending =
              bookings.where((b) => b.status == BookingStatus.pending).toList();
          final others =
              bookings.where((b) => b.status != BookingStatus.pending).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (pending.isNotEmpty) ...[
                _sectionHeader('🔔 New Requests (${pending.length})'),
                ...pending.map((b) => _bookingCard(context, b, service)),
                const SizedBox(height: 16),
              ],
              if (others.isNotEmpty) ...[
                _sectionHeader('History'),
                ...others.map((b) => _bookingCard(context, b, service)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _bookingCard(
      BuildContext context, BookingModel b, CaregiverFirestoreService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.familyName,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    Text(
                      b.specialization,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: b.status),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          // Details
          _detailRow(Icons.calendar_today_outlined,
              '${b.dateTime.day}/${b.dateTime.month}/${b.dateTime.year}'),
          const SizedBox(height: 6),
          _detailRow(Icons.access_time_rounded,
              '${b.dateTime.hour.toString().padLeft(2, '0')}:${b.dateTime.minute.toString().padLeft(2, '0')}'),
          const SizedBox(height: 6),
          _detailRow(Icons.payments_outlined,
              'Rp ${(b.pricePerHour / 1000).toStringAsFixed(0)}k/jam'),
          if (b.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            _detailRow(Icons.note_outlined, b.notes),
          ],

          // Action buttons (only for pending)
          if (b.status == BookingStatus.pending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.cancelled,
                      side: const BorderSide(color: AppColors.cancelled),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => service.updateBookingStatus(
                        b.bookingId, BookingStatus.cancelled),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => service.updateBookingStatus(
                        b.bookingId, BookingStatus.accepted),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],

          // Complete button (only for accepted)
          if (b.status == BookingStatus.accepted) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.completed,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => service.updateBookingStatus(
                    b.bookingId, BookingStatus.completed),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark as Complete'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
