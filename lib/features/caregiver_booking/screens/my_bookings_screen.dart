import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../features/auth/services/auth_provider.dart';
import '../../admin/services/admin_service.dart';
import '../models/booking_model.dart';
import '../services/caregiver_firestore_service.dart';
import '../widgets/status_badge.dart';

/// My Bookings Screen — shows all caregiver bookings made by the logged-in user.
class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.currentUser?.uid ?? '';
    final userName = auth.userName.isNotEmpty
        ? auth.userName
        : (auth.currentUser?.email ?? 'Pengguna');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Pesananku',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: CaregiverBookingsBody(uid: uid, userName: userName),
    );
  }
}

/// Body-only widget — reusable inside tab views without an AppBar.
class CaregiverBookingsBody extends StatelessWidget {
  final String uid;
  final String userName;
  const CaregiverBookingsBody({
    super.key,
    required this.uid,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final service = CaregiverFirestoreService();
    final adminService = AdminService();

    return StreamBuilder<List<BookingModel>>(
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
                Text('Belum ada booking caregiver',
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
              ...active.map((b) => _BookingCard(
                    booking: b,
                    service: service,
                    adminService: adminService,
                    userId: uid,
                    userName: userName,
                  )),
              const SizedBox(height: 16),
            ],
            if (history.isNotEmpty) ...[
              _sectionHeader('Riwayat'),
              ...history.map((b) => _BookingCard(
                    booking: b,
                    service: service,
                    adminService: adminService,
                    userId: uid,
                    userName: userName,
                  )),
            ],
          ],
        );
      },
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
}

// ════════════════════════════════════════════════════════════════════════════
//  Booking Card (stateful for review check)
// ════════════════════════════════════════════════════════════════════════════
class _BookingCard extends StatefulWidget {
  final BookingModel booking;
  final CaregiverFirestoreService service;
  final AdminService adminService;
  final String userId;
  final String userName;

  const _BookingCard({
    required this.booking,
    required this.service,
    required this.adminService,
    required this.userId,
    required this.userName,
  });

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  bool _hasReview = false;

  @override
  void initState() {
    super.initState();
    if (widget.booking.status == BookingStatus.completed) {
      widget.adminService.hasReview(widget.booking.bookingId).then((val) {
        if (mounted) setState(() => _hasReview = val);
      });
    }
  }

  BookingModel get b => widget.booking;

  @override
  Widget build(BuildContext context) {
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
        // ── Header ──────────────────────────────────────────────────────
        Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryLight,
            child: const Icon(Icons.medical_services,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b.caregiverName,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text(b.specialization,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            StatusBadge(status: b.status),
            const SizedBox(height: 4),
            // Report button (small, always visible)
            GestureDetector(
              onTap: () => _showReportDialog(context),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.flag_outlined, size: 12, color: AppColors.cancelled),
                SizedBox(width: 3),
                Text('Laporkan',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.cancelled,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ]),

        const SizedBox(height: 12),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 12),

        // ── Details ─────────────────────────────────────────────────────
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

        // ── Actions ─────────────────────────────────────────────────────
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
              onPressed: () => _confirmCancel(context),
            ),
          ),
        ] else if (b.status == BookingStatus.completed) ...[
          const SizedBox(height: 14),
          // Review button (only if not reviewed yet)
          if (!_hasReview)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.star_rounded, size: 18),
                label: const Text('Beri Ulasan'),
                onPressed: () => _showReviewDialog(context),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFD54F)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_rounded,
                      color: Color(0xFFFFC107), size: 16),
                  SizedBox(width: 6),
                  Text('Ulasan sudah diberikan',
                      style: TextStyle(
                          color: Color(0xFF8D6E00),
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Hapus Riwayat'),
              onPressed: () => _confirmDelete(context),
            ),
          ),
        ] else if (b.status == BookingStatus.cancelled) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Hapus Riwayat'),
              onPressed: () => _confirmDelete(context),
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
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
      ),
    ]);
  }

  // ── Review Dialog ────────────────────────────────────────────────────────
  void _showReviewDialog(BuildContext context) {
    double rating = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Ulasan untuk ${b.caregiverName}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Bagaimana layanan caregiver ini?',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            // Star rating row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return GestureDetector(
                  onTap: () => setInner(() => rating = i + 1.0),
                  child: Icon(
                    i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFFFC107),
                    size: 36,
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),
            Text('${rating.toInt()} Bintang',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: commentCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Komentar (opsional)',
                hintText: 'Ceritakan pengalamanmu...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                await widget.adminService.submitReview(
                  bookingId: b.bookingId,
                  caregiverId: b.caregiverId,
                  caregiverName: b.caregiverName,
                  userId: widget.userId,
                  userName: widget.userName,
                  rating: rating,
                  comment: commentCtrl.text.trim(),
                );
                if (!mounted) return;
                setState(() => _hasReview = true);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('✅ Ulasan berhasil dikirim!'),
                      backgroundColor: AppColors.accepted),
                );
              },
              child: const Text('Kirim Ulasan'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Report Dialog ────────────────────────────────────────────────────────
  void _showReportDialog(BuildContext context) {
    String selectedReason = 'Perilaku tidak profesional';
    final descCtrl = TextEditingController();
    final reasons = [
      'Perilaku tidak profesional',
      'Tidak datang sesuai jadwal',
      'Layanan tidak sesuai deskripsi',
      'Meminta biaya tambahan',
      'Penipuan atau kecurangan',
      'Lainnya',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          title: Text('Laporkan ${b.caregiverName}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(height: 8),
                const Text(
                    'Laporan kamu akan ditinjau oleh tim admin Healink.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedReason,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Alasan Laporan',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  items: reasons
                      .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) =>
                      setInner(() => selectedReason = v ?? selectedReason),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Keterangan Tambahan',
                    hintText: 'Jelaskan kejadian...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
              ),
            ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cancelled),
              onPressed: () async {
                await widget.adminService.submitReport(
                  reporterId: widget.userId,
                  reporterName: widget.userName,
                  reporterRole: 'user',
                  targetId: b.caregiverId,
                  targetName: b.caregiverName,
                  targetType: 'caregiver',
                  reason: selectedReason,
                  description: descCtrl.text.trim(),
                  bookingId: b.bookingId,
                );
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            '📋 Laporan dikirim. Tim admin akan meninjau segera.'),
                        backgroundColor: AppColors.primary),
                  );
                }
              },
              child: const Text('Kirim Laporan'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Cancel / Delete ──────────────────────────────────────────────────────
  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              child: const Text('Tidak')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cancelled),
            onPressed: () {
              widget.service.cancelBooking(b.bookingId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Pesanan dibatalkan'),
                    backgroundColor: AppColors.cancelled),
              );
            },
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Riwayat?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'Riwayat pesanan ini akan dihapus secara permanen dari daftar kamu.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cancelled),
            onPressed: () {
              widget.service.deleteBookingHistory(b.bookingId);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
