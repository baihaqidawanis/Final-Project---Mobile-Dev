import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../features/auth/services/auth_provider.dart';
import '../models/booking_model.dart';
import '../services/caregiver_firestore_service.dart';
import '../widgets/status_badge.dart';

/// My Bookings Screen — shows all bookings made by the logged-in user.
/// User can CANCEL any booking that is still pending (CRUD Delete).
class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.currentUser?.uid ?? '';
    final service = CaregiverFirestoreService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Pesananku',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: service.getBookingsByFamily(uid),
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
                  Icon(Icons.calendar_today_outlined,
                      size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('Belum ada pesanan',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  SizedBox(height: 8),
                  Text('Pesan caregiver dari halaman utama',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            );
          }

          // Split into active (pending/accepted) and history
          final active = bookings
              .where((b) =>
                  b.status == BookingStatus.pending ||
                  b.status == BookingStatus.accepted)
              .toList();
          final history = bookings
              .where((b) =>
                  b.status == BookingStatus.completed ||
                  b.status == BookingStatus.cancelled)
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (active.isNotEmpty) ...[
                _sectionHeader('🟢 Pesanan Aktif'),
                ...active.map((b) => _bookingCard(context, b, service)),
                const SizedBox(height: 16),
              ],
              if (history.isNotEmpty) ...[
                _sectionHeader('Riwayat'),
                ...history.map((b) => _bookingCard(context, b, service)),
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
      child: Text(title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
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
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header: caregiver name + status badge
        Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryLight,
            child: const Icon(Icons.medical_services, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                b.caregiverName,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              Text(
                b.specialization,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ]),
          ),
          StatusBadge(status: b.status),
        ]),

        const SizedBox(height: 12),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 12),

        // Details
        _detailRow(Icons.calendar_today_outlined,
            '${b.dateTime.day}/${b.dateTime.month}/${b.dateTime.year}'),
        const SizedBox(height: 4),
        _detailRow(Icons.access_time_rounded,
            '${b.dateTime.hour.toString().padLeft(2, '0')}:${b.dateTime.minute.toString().padLeft(2, '0')}'),
        const SizedBox(height: 4),
        _detailRow(Icons.payments_outlined,
            'Rp ${(b.pricePerHour / 1000).toStringAsFixed(0)}k/jam'),
        if (b.notes.isNotEmpty) ...[
          const SizedBox(height: 4),
          _detailRow(Icons.note_outlined, b.notes),
        ],

        // Cancel button — only for PENDING bookings (CRUD Delete)
        if (b.status == BookingStatus.pending) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.cancelled,
                side: const BorderSide(color: AppColors.cancelled),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Batalkan Pesanan'),
              onPressed: () => _confirmCancel(context, b, service),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ),
    ]);
  }

  void _confirmCancel(
      BuildContext context, BookingModel b, CaregiverFirestoreService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pesanan?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Batalkan booking dengan ${b.caregiverName} pada '
          '${b.dateTime.day}/${b.dateTime.month}/${b.dateTime.year}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.cancelled),
            onPressed: () {
              service.cancelBooking(b.bookingId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pesanan dibatalkan'),
                  backgroundColor: AppColors.cancelled,
                ),
              );
            },
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
  }
}
