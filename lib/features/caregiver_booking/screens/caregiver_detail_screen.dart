import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../features/auth/screens/login_screen.dart';
import '../models/booking_model.dart';
import '../models/caregiver_profile_model.dart';
import '../services/caregiver_firestore_service.dart';
import '../widgets/status_badge.dart';

class CaregiverDetailScreen extends StatefulWidget {
  final CaregiverProfileModel caregiver;
  final String familyId;
  final String familyName;
  final bool isGuest;

  const CaregiverDetailScreen({
    super.key,
    required this.caregiver,
    required this.familyId,
    required this.familyName,
    this.isGuest = false,
  });

  @override
  State<CaregiverDetailScreen> createState() => _CaregiverDetailScreenState();
}

class _CaregiverDetailScreenState extends State<CaregiverDetailScreen> {
  final _service = CaregiverFirestoreService();
  final _notesCtrl = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  /// Guard against double-booking: check if family already has an active
  /// (pending/accepted) booking with this caregiver before creating a new one.
  Future<void> _submitBooking() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Pilih tanggal dan waktu terlebih dahulu'),
          backgroundColor: AppColors.pending,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // ── Double-booking guard ──────────────────────────────────────────────
    try {
      final existing = await _service.db
          .collection('bookings')
          .where('familyId', isEqualTo: widget.familyId)
          .where('caregiverId', isEqualTo: widget.caregiver.uid)
          .where('status', whereIn: ['pending', 'accepted'])
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty && mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '⚠️ Kamu sudah punya booking aktif dengan caregiver ini. Tunggu sampai selesai atau batalkan dulu.'),
            backgroundColor: AppColors.pending,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }
    } catch (_) {
      // Silently continue if check fails (network issue etc.)
    }
    // ─────────────────────────────────────────────────────────────────────

    final dateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final booking = BookingModel(
      bookingId: '',
      familyId: widget.familyId,
      caregiverId: widget.caregiver.uid,
      caregiverName: widget.caregiver.name,
      familyName: widget.familyName,
      dateTime: dateTime,
      specialization: widget.caregiver.specialization,
      pricePerHour: widget.caregiver.pricePerHour,
      notes: _notesCtrl.text.trim(),
      status: BookingStatus.pending,
      createdAt: DateTime.now(),
    );

    await _service.createBooking(booking);

    // 🔔 Send push notification to caregiver (fire & forget — doesn't block UI)
    NotificationService().sendNotificationToUser(
      targetUid: widget.caregiver.uid,
      title: '📋 Booking Baru!',
      body:
          '${widget.familyName} memesan layanan ${widget.caregiver.specialization} kamu.',
      data: {
        'type': 'new_booking',
        'familyId': widget.familyId,
        'familyName': widget.familyName,
      },
    );


    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Booking berhasil dikirim! Tunggu konfirmasi caregiver.'),
          backgroundColor: AppColors.accepted,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  /// Confirm dialog before cancelling a booking from the detail screen.
  void _confirmCancel(BookingModel b) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pesanan?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Batalkan booking dengan ${widget.caregiver.name} pada '
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
              _service.cancelBooking(b.bookingId);
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



  @override
  Widget build(BuildContext context) {
    final c = widget.caregiver;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar with avatar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.primary,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 3),
                      ),
                      child: c.photoUrl.isNotEmpty
                          ? ClipOval(
                              child: c.photoUrl.startsWith('data:image')
                                  ? Image.memory(
                                      base64Decode(
                                          c.photoUrl.split(',').last),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 44),
                                    )
                                  : Image.network(
                                      c.photoUrl,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 44),
                                    ),
                            )
                          : const Icon(Icons.person,
                              color: Colors.white, size: 44),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      c.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info chips
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _infoBadge(Icons.work_outline, c.specialization, AppColors.primary),
                      _infoBadge(Icons.star_rounded,
                          '${c.rating} (${c.totalReviews} reviews)',
                          const Color(0xFFFFC107)),
                      _infoBadge(Icons.payments_outlined,
                          'Rp ${(c.pricePerHour / 1000).toStringAsFixed(0)}k/jam',
                          AppColors.accent),
                      if (c.area.isNotEmpty)
                        _infoBadge(Icons.location_on_outlined, c.area, AppColors.textSecondary),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Bio
                  const Text('Tentang Caregiver', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text(
                    c.bio.isNotEmpty ? c.bio : 'Belum ada deskripsi.',
                    style: const TextStyle(color: AppColors.textSecondary, height: 1.6),
                  ),
                  const SizedBox(height: 28),

                  const Divider(color: AppColors.border),
                  const SizedBox(height: 20),

                  // Booking form
                  const Text('Buat Booking', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),

                  _dateTimeTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Tanggal',
                    value: _selectedDate == null
                        ? 'Pilih tanggal'
                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    onTap: _pickDate,
                    filled: _selectedDate != null,
                  ),
                  const SizedBox(height: 12),

                  _dateTimeTile(
                    icon: Icons.access_time_rounded,
                    label: 'Jam Mulai',
                    value: _selectedTime == null
                        ? 'Pilih waktu'
                        : _selectedTime!.format(context),
                    onTap: _pickTime,
                    filled: _selectedTime != null,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Catatan Khusus (opsional)',
                      hintText: 'Kebutuhan khusus, kondisi pasien, dll...',
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.note_outlined),
                      ),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 28),

                  if (!widget.isGuest) _buildMyBookings(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: ElevatedButton.icon(
          onPressed: _isLoading
              ? null
              : () {
                  if (widget.isGuest) {
                    // Show login prompt bottom sheet
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 40, height: 4,
                                decoration: BoxDecoration(color: AppColors.border,
                                    borderRadius: BorderRadius.circular(2))),
                            const SizedBox(height: 20),
                            const Icon(Icons.lock_outline, size: 40, color: AppColors.primary),
                            const SizedBox(height: 12),
                            const Text('Masuk untuk Memesan', style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            const SizedBox(height: 8),
                            const Text('Kamu perlu masuk dulu untuk membuat booking',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textSecondary)),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => const LoginScreen()));
                                },
                                child: const Text('Masuk / Daftar'),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                  } else {
                    _submitBooking();
                  }
                },
          icon: _isLoading
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Icon(widget.isGuest ? Icons.login : Icons.check_circle_outline),
          label: Text(_isLoading ? 'Mengirim...' : widget.isGuest ? 'Masuk untuk Memesan' : 'Kirim Booking'),
        ),
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _dateTimeTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool filled,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: filled ? AppColors.primary.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: filled ? AppColors.primary : AppColors.border,
            width: filled ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: filled ? AppColors.primary : AppColors.textSecondary,
                size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  Text(value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: filled
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      )),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildMyBookings() {
    return StreamBuilder<List<BookingModel>>(
      stream: _service.getBookingsByFamily(widget.familyId),
      builder: (context, snapshot) {
        final bookings = snapshot.data
                ?.where((b) => b.caregiverId == widget.caregiver.uid)
                .toList() ??
            [];
        if (bookings.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: AppColors.border),
            const SizedBox(height: 16),
            const Text('Booking Kamu dengan Caregiver Ini',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            ...bookings.map((b) => _bookingTile(b)),
          ],
        );
      },
    );
  }

  Widget _bookingTile(BookingModel b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${b.dateTime.day}/${b.dateTime.month}/${b.dateTime.year} · ${b.dateTime.hour.toString().padLeft(2, '0')}:${b.dateTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                if (b.notes.isNotEmpty)
                  Text(b.notes,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            children: [
              StatusBadge(status: b.status),
              if (b.status == BookingStatus.pending) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _confirmCancel(b),
                  child: const Text('Cancel',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.cancelled,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
