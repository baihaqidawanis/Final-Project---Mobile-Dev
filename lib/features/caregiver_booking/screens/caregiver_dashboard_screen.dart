import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../features/auth/services/auth_provider.dart';
import '../models/booking_model.dart';
import '../services/caregiver_firestore_service.dart';
import '../widgets/status_badge.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = CaregiverFirestoreService();

  // Profile edit controllers
  final _nameCtrl = TextEditingController();
  final _specializationCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _isAvailable = true;
  bool _savingProfile = false;
  bool _profileLoaded = false;
  bool _uploadingPhoto = false;
  String _currentPhotoUrl = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  /// Returns a stream of active bookings. Firestore automatically handles local caching
  /// so calling this multiple times for different StreamBuilders is perfectly fine.
  Stream<List<BookingModel>> _getActiveStream(String uid) {
    return _service.getActiveBookingsByCaregiver(uid);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _specializationCtrl.dispose();
    _priceCtrl.dispose();
    _areaCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(String uid) async {
    setState(() => _savingProfile = true);
    await _service.updateCaregiverProfile(uid, {
      'name': _nameCtrl.text.trim(),
      'specialization': _specializationCtrl.text.trim(),
      'pricePerHour': double.tryParse(_priceCtrl.text.trim()) ?? 0,
      'area': _areaCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
      'isAvailable': _isAvailable,
    });
    if (mounted) {
      setState(() => _savingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Profil berhasil diperbarui'),
          backgroundColor: AppColors.accepted,
        ),
      );
    }
  }

  // ── Pick & upload profile photo ──────────────────────────────────────────
  Future<void> _pickAndUploadPhoto(String uid) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
      maxWidth: 400,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await _service.uploadProfilePhoto(
        uid: uid,
        bytes: bytes,
        contentType: picked.mimeType ?? 'image/jpeg',
      );
      if (mounted) setState(() => _currentPhotoUrl = url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto profil berhasil diperbarui'),
            backgroundColor: AppColors.accepted,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal upload foto: $e'),
            backgroundColor: AppColors.cancelled,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Widget _buildFallbackAvatar() {
    return Center(
      child: Text(
        _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : 'C',
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  // ── Accept booking + notify family ───────────────────────────────────────
  Future<void> _acceptBooking(BookingModel b) async {
    await _service.updateBookingStatus(b.bookingId, BookingStatus.accepted);
    NotificationService().sendNotificationToUser(
      targetUid: b.familyId,
      title: '✅ Booking Diterima!',
      body: 'Caregiver $_nameForNotif telah menerima booking kamu. '
          'Tanggal: ${b.dateTime.day}/${b.dateTime.month}/${b.dateTime.year}.',
      data: {'type': 'booking_accepted', 'bookingId': b.bookingId},
    );
  }

  // ── Decline booking + notify family ─────────────────────────────────────
  Future<void> _declineBooking(BookingModel b) async {
    await _service.updateBookingStatus(b.bookingId, BookingStatus.cancelled);
    NotificationService().sendNotificationToUser(
      targetUid: b.familyId,
      title: '❌ Booking Ditolak',
      body: 'Maaf, caregiver $_nameForNotif tidak bisa menerima booking kamu. '
          'Silakan pilih caregiver lain.',
      data: {'type': 'booking_declined', 'bookingId': b.bookingId},
    );
  }

  String get _nameForNotif => _nameCtrl.text.isNotEmpty ? _nameCtrl.text.trim() : 'kami';

  Future<void> _showCompleteDialog(BookingModel b) async {
    final noteCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.completed),
            SizedBox(width: 10),
            Text('Tandai Selesai',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Klien: ${b.familyName}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Catatan Klinis',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Kondisi pasien, tindakan yang diberikan...',
                hintStyle:
                    const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Opsional — akan disimpan sebagai log layanan',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.completed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, noteCtrl.text),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Selesaikan'),
          ),
        ],
      ),
    );
    noteCtrl.dispose();

    if (result != null) {
      await _service.completeBookingWithNote(b.bookingId, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, ${auth.userName.split(' ').first} 👋',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Text(
              'Dashboard Caregiver',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            tooltip: 'Keluar',
            onPressed: () => _confirmLogout(context, auth),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: StreamBuilder<List<BookingModel>>(
            stream: _getActiveStream(uid),
            builder: (context, snap) {
              final pendingCount = snap.data
                      ?.where((b) => b.status == BookingStatus.pending)
                      .length ??
                  0;

              return TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.assignment_outlined, size: 18),
                        const SizedBox(width: 6),
                        const Text('Requests'),
                        if (pendingCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.pending,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$pendingCount',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_outline, size: 18),
                        SizedBox(width: 6),
                        Text('Profil Saya'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestsTab(uid),
          _buildProfileTab(uid),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content:
            const Text('Kamu akan keluar dari akun caregiver ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cancelled),
            onPressed: () {
              Navigator.pop(ctx);
              auth.logout();
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  // ── TAB 1: Active Requests Only ──────────────────────────────────────────
  Widget _buildRequestsTab(String uid) {
    if (uid.isEmpty) {
      return const Center(child: Text('Silakan login ulang'));
    }
    return StreamBuilder<List<BookingModel>>(
      stream: _getActiveStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return _buildEmptyRequests();
        }

        final pending =
            bookings.where((b) => b.status == BookingStatus.pending).toList();
        final accepted =
            bookings.where((b) => b.status == BookingStatus.accepted).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            if (pending.isNotEmpty) ...[
              _sectionHeader(
                  '🔔 Request Baru (${pending.length})', AppColors.pending),
              ...pending.map((b) => _bookingCard(b)),
              const SizedBox(height: 16),
            ],
            if (accepted.isNotEmpty) ...[
              _sectionHeader(
                  '🟢 Sedang Berjalan (${accepted.length})', AppColors.accepted),
              ...accepted.map((b) => _bookingCard(b)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEmptyRequests() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 52,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tidak ada request aktif',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Request booking dari keluarga akan\nmuncul di sini secara real-time',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TAB 2: Edit Profile ──────────────────────────────────────────────────
  Widget _buildProfileTab(String uid) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _service.getCaregiverProfileStream(uid),
      builder: (context, snapshot) {
        if (snapshot.hasData && !_profileLoaded) {
          final data = snapshot.data;
          if (data != null) {
            _nameCtrl.text = data['name'] ?? '';
            _specializationCtrl.text = data['specialization'] ?? '';
            _priceCtrl.text = (data['pricePerHour'] ?? '').toString();
            _areaCtrl.text = data['area'] ?? '';
            _bioCtrl.text = data['bio'] ?? '';
            _isAvailable = data['isAvailable'] ?? true;
            _currentPhotoUrl = data['photoUrl'] ?? '';
            _profileLoaded = true;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with photo upload
              Center(
                child: GestureDetector(
                  onTap: _uploadingPhoto ? null : () => _pickAndUploadPhoto(uid),
                  child: Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: _uploadingPhoto
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : _currentPhotoUrl.isNotEmpty
                                ? ClipOval(
                                    child: _currentPhotoUrl.startsWith('data:image')
                                        ? Image.memory(
                                            base64Decode(_currentPhotoUrl.split(',').last),
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, _) => _buildFallbackAvatar(),
                                          )
                                        : Image.network(
                                            _currentPhotoUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, _) => _buildFallbackAvatar(),
                                          ),
                                  )
                                : _buildFallbackAvatar(),
                      ),
                      // Camera icon overlay
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Profil Caregiver',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              _formLabel('Informasi Profil'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _specializationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Spesialisasi',
                  hintText: 'cth: Elderly Care, Post-Surgery',
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga per Jam (Rp)',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _areaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Daerah Operasional',
                  hintText: 'cth: Jakarta Selatan',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _bioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Diri',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.description_outlined),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              // Availability toggle
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isAvailable
                        ? AppColors.accepted.withValues(alpha: 0.4)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isAvailable
                            ? AppColors.accepted.withValues(alpha: 0.1)
                            : AppColors.textSecondary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isAvailable
                            ? Icons.wifi_tethering_rounded
                            : Icons.wifi_tethering_off_rounded,
                        size: 18,
                        color: _isAvailable
                            ? AppColors.accepted
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isAvailable
                                ? 'Tersedia untuk Booking'
                                : 'Tidak Tersedia',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _isAvailable
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            _isAvailable
                                ? 'Profil kamu muncul di daftar pencarian'
                                : 'Profil kamu disembunyikan sementara',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isAvailable,
                      activeThumbColor: AppColors.accepted,
                      onChanged: (v) => setState(() => _isAvailable = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _savingProfile ? null : () => _saveProfile(uid),
                  icon: _savingProfile
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_rounded),
                  label: Text(_savingProfile ? 'Menyimpan...' : 'Simpan Profil',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _formLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookingCard(BookingModel b) {
    final isPending = b.status == BookingStatus.pending;
    final isAccepted = b.status == BookingStatus.accepted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPending
              ? AppColors.pending.withValues(alpha: 0.35)
              : AppColors.accepted.withValues(alpha: 0.25),
          width: isPending ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPending ? AppColors.pending : AppColors.accepted)
                .withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card header stripe
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isPending
                  ? AppColors.pending.withValues(alpha: 0.05)
                  : AppColors.accepted.withValues(alpha: 0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    b.familyName.isNotEmpty ? b.familyName[0].toUpperCase() : 'K',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
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
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        b.specialization,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: b.status),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    _chip(Icons.calendar_today_outlined,
                        '${b.dateTime.day}/${b.dateTime.month}/${b.dateTime.year}'),
                    const SizedBox(width: 10),
                    _chip(Icons.access_time_rounded,
                        '${b.dateTime.hour.toString().padLeft(2, '0')}:${b.dateTime.minute.toString().padLeft(2, '0')}'),
                    const SizedBox(width: 10),
                    _chip(Icons.payments_outlined,
                        'Rp ${_fmt(b.pricePerHour)}/jam'),
                  ],
                ),
                if (b.notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.note_outlined,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            b.notes,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Pending: Accept / Decline buttons
                if (isPending)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.cancelled,
                            side: const BorderSide(color: AppColors.cancelled),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () => _confirmDecline(b),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Tolak',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () => _acceptBooking(b),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Terima',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),

                // Accepted: Complete with note
                if (isAccepted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.completed,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _showCompleteDialog(b),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Tandai Selesai',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDecline(BookingModel b) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tolak Request?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Tolak booking dari ${b.familyName}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.cancelled),
            onPressed: () {
              _declineBooking(b);
              Navigator.pop(ctx);
            },
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double price) {
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}k';
    return price.toStringAsFixed(0);
  }
}
