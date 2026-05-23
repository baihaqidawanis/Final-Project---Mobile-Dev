import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../features/auth/services/auth_provider.dart';
import '../models/booking_model.dart';
import '../services/caregiver_firestore_service.dart';
import '../widgets/status_badge.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() => _CaregiverDashboardScreenState();
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        const SnackBar(content: Text('✅ Profil berhasil diperbarui'),
            backgroundColor: AppColors.accepted),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Dashboard Caregiver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            onPressed: () => auth.logout(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.assignment_outlined), text: 'Requests'),
            Tab(icon: Icon(Icons.person_outline), text: 'Profil Saya'),
          ],
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

  // ── TAB 1: Incoming Requests ─────────────────────────────────────────────
  Widget _buildRequestsTab(String uid) {
    if (uid.isEmpty) {
      return const Center(child: Text('Silakan login ulang'));
    }
    return StreamBuilder<List<BookingModel>>(
      stream: _service.getBookingsByCaregiver(uid),
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
                Icon(Icons.inbox_outlined, size: 64, color: AppColors.textSecondary),
                SizedBox(height: 16),
                Text('Belum ada request masuk', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                SizedBox(height: 8),
                Text('Booking akan muncul di sini', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        final pending = bookings.where((b) => b.status == BookingStatus.pending).toList();
        final others = bookings.where((b) => b.status != BookingStatus.pending).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (pending.isNotEmpty) ...[
              _sectionHeader('🔔 Request Baru (${pending.length})'),
              ...pending.map((b) => _bookingCard(b)),
              const SizedBox(height: 16),
            ],
            if (others.isNotEmpty) ...[
              _sectionHeader('Riwayat'),
              ...others.map((b) => _bookingCard(b)),
            ],
          ],
        );
      },
    );
  }

  // ── TAB 2: Edit Profile ──────────────────────────────────────────────────
  Widget _buildProfileTab(String uid) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: Stream.fromFuture(
        FirestoreProfileFuture.getProfile(_service, uid),
      ),
      builder: (context, snapshot) {
        // Pre-fill controllers if data arrived and fields are empty
        if (snapshot.hasData && _nameCtrl.text.isEmpty) {
          final data = snapshot.data;
          if (data != null) {
            _nameCtrl.text = data['name'] ?? '';
            _specializationCtrl.text = data['specialization'] ?? '';
            _priceCtrl.text = (data['pricePerHour'] ?? '').toString();
            _areaCtrl.text = data['area'] ?? '';
            _bioCtrl.text = data['bio'] ?? '';
            _isAvailable = data['isAvailable'] ?? true;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar placeholder
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : 'C',
                        style: const TextStyle(
                          fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text('Foto profil coming soon',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 28),

              const Text('Informasi Profil', style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
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
                  hintText: 'cth: Elderly Care',
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
              const SizedBox(height: 16),

              // Availability toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 10, color: AppColors.accepted),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Tersedia untuk booking',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                    ),
                    Switch(
                      value: _isAvailable,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _isAvailable = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              ElevatedButton.icon(
                onPressed: _savingProfile ? null : () => _saveProfile(uid),
                icon: _savingProfile
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(_savingProfile ? 'Menyimpan...' : 'Simpan Profil'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(title, style: const TextStyle(
        fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    );
  }

  Widget _bookingCard(BookingModel b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 20, backgroundColor: AppColors.primaryLight,
              child: const Icon(Icons.person, color: AppColors.primary, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.familyName, style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text(b.specialization, style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary)),
          ])),
          StatusBadge(status: b.status),
        ]),
        const SizedBox(height: 12),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 12),
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

        if (b.status == BookingStatus.pending) ...[
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cancelled,
                  side: const BorderSide(color: AppColors.cancelled),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _service.updateBookingStatus(b.bookingId, BookingStatus.cancelled),
                child: const Text('Tolak'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () => _service.updateBookingStatus(b.bookingId, BookingStatus.accepted),
                child: const Text('Terima'),
              ),
            ),
          ]),
        ],

        if (b.status == BookingStatus.accepted) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.completed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => _service.updateBookingStatus(b.bookingId, BookingStatus.completed),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Tandai Selesai'),
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
      Expanded(child: Text(text,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
    ]);
  }
}

/// Helper to fetch caregiver profile as a Future for StreamBuilder
class FirestoreProfileFuture {
  static Future<Map<String, dynamic>?> getProfile(
      CaregiverFirestoreService service, String uid) async {
    if (uid.isEmpty) return null;
    final db = service.db;
    final doc = await db.collection('caregivers').doc(uid).get();
    return doc.data();
  }
}
