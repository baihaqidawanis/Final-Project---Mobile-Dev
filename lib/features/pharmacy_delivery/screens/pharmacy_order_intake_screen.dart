import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/services/auth_provider.dart';
import '../models/medicine_model.dart';
import '../models/pharmacy_order_model.dart';
import '../services/pharmacy_firestore_service.dart';

const _kPurple = Color(0xFF7B5EA7);

class PharmacyOrderIntakeScreen extends StatefulWidget {
  const PharmacyOrderIntakeScreen({super.key});

  @override
  State<PharmacyOrderIntakeScreen> createState() =>
      _PharmacyOrderIntakeScreenState();
}

class _PharmacyOrderIntakeScreenState extends State<PharmacyOrderIntakeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = PharmacyFirestoreService();

  // Profile edit controllers
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _openHoursCtrl = TextEditingController();
  bool _isOpen = true;
  bool _savingProfile = false;
  bool _profileLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _areaCtrl.dispose();
    _phoneCtrl.dispose();
    _openHoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(String uid) async {
    setState(() => _savingProfile = true);
    await _service.updatePharmacyProfile(uid, {
      'name': _nameCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'area': _areaCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'openHours': _openHoursCtrl.text.trim(),
      'isOpen': _isOpen,
    });
    if (mounted) {
      setState(() => _savingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil apotek berhasil diperbarui'),
          backgroundColor: AppColors.accepted,
        ),
      );
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
        title: const Text(
          'Dashboard Apotek',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            onPressed: () => auth.logout(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPurple,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: _kPurple,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Pesanan'),
            Tab(icon: Icon(Icons.medication_outlined), text: 'Katalog'),
            Tab(icon: Icon(Icons.store_outlined), text: 'Profil'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersTab(uid),
          _buildCatalogTab(uid),
          _buildProfileTab(uid),
        ],
      ),
    );
  }

  // ── TAB 1: Incoming Orders ───────────────────────────────────────────────

  Widget _buildOrdersTab(String uid) {
    if (uid.isEmpty) {
      return const Center(child: Text('Silakan login ulang'));
    }
    return StreamBuilder<List<PharmacyOrderModel>>(
      stream: _service.getOrdersByPharmacy(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snap.data ?? [];
        if (orders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 16),
                Text(
                  'Belum ada pesanan masuk',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Pesanan dari pelanggan akan muncul di sini',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        final pending = orders
            .where((o) => o.status == PharmacyOrderStatus.pending)
            .toList();
        final active = orders
            .where(
              (o) =>
                  o.status == PharmacyOrderStatus.accepted ||
                  o.status == PharmacyOrderStatus.shipped,
            )
            .toList();
        final done = orders
            .where(
              (o) =>
                  o.status == PharmacyOrderStatus.delivered ||
                  o.status == PharmacyOrderStatus.cancelled,
            )
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (pending.isNotEmpty) ...[
              _sectionHeader('Menunggu Konfirmasi (${pending.length})'),
              ...pending.map((o) => _orderCard(o)),
              const SizedBox(height: 8),
            ],
            if (active.isNotEmpty) ...[
              _sectionHeader('Dikemas & Pengiriman (${active.length})'),
              ...active.map((o) => _orderCard(o)),
              const SizedBox(height: 8),
            ],
            if (done.isNotEmpty) ...[
              _sectionHeader('Selesai / Dibatalkan'),
              ...done.map((o) => _orderCard(o)),
            ],
          ],
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _orderCard(PharmacyOrderModel o) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM, HH:mm');

    Color statusColor;
    String statusLabel;
    switch (o.status) {
      case PharmacyOrderStatus.pending:
        statusColor = AppColors.pending;
        statusLabel = 'Menunggu';
        break;
      case PharmacyOrderStatus.accepted:
        statusColor = AppColors.accepted;
        statusLabel = 'Dikemas';
        break;
      case PharmacyOrderStatus.shipped:
        statusColor = const Color(0xFF2196F3);
        statusLabel = 'Dikirim';
        break;
      case PharmacyOrderStatus.delivered:
        statusColor = AppColors.accepted;
        statusLabel = 'Terkirim';
        break;
      case PharmacyOrderStatus.cancelled:
        statusColor = AppColors.cancelled;
        statusLabel = 'Dibatalkan';
        break;
    }

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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _kPurple.withValues(alpha: 0.12),
                child: const Icon(Icons.person, color: _kPurple, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.userName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      dateFormat.format(o.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Text(
            o.items.map((e) => '${e.quantity}x ${e.medicineName}').join(', '),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 13,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  o.deliveryAddress,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                currency.format(o.totalPrice),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _kPurple,
                ),
              ),
            ],
          ),
          if (o.notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.note_outlined,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    o.notes,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (o.prescriptionImageUrl != null &&
              o.prescriptionImageUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kPurple.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kPurple.withValues(alpha: 0.16)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      o.prescriptionImageUrl!,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 54,
                        height: 54,
                        color: AppColors.border,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Resep dokter terlampir',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action buttons
          if (o.status == PharmacyOrderStatus.pending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.cancelled,
                      side: const BorderSide(color: AppColors.cancelled),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _service.updateOrderStatus(
                      o.orderId,
                      PharmacyOrderStatus.cancelled,
                    ),
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _service.updateOrderStatus(
                      o.orderId,
                      PharmacyOrderStatus.accepted,
                    ),
                    child: const Text('Terima & Kemas'),
                  ),
                ),
              ],
            ),
          ],

          if (o.status == PharmacyOrderStatus.accepted) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _service.updateOrderStatus(
                  o.orderId,
                  PharmacyOrderStatus.shipped,
                ),
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('Kirim Pesanan'),
              ),
            ),
          ],

          if (o.status == PharmacyOrderStatus.shipped) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.25),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.schedule, size: 15, color: Color(0xFF2196F3)),
                  SizedBox(width: 8),
                  Text(
                    'Menunggu konfirmasi penerimaan dari customer',
                    style: TextStyle(fontSize: 12, color: Color(0xFF2196F3)),
                  ),
                ],
              ),
            ),
          ],

          if (o.status == PharmacyOrderStatus.delivered) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accepted.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.accepted.withValues(alpha: 0.2),
                ),
              ),
              child: o.rating != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Color(0xFFFFC107),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Rating: ${o.rating!.toStringAsFixed(0)}/5',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < o.rating!.round()
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 14,
                                  color: const Color(0xFFFFC107),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (o.review != null && o.review!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            '"${o.review}"',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    )
                  : const Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: AppColors.accepted,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Selesai — customer tidak memberi rating',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }

  // ── TAB 2: Medicine Catalog ──────────────────────────────────────────────

  Widget _buildCatalogTab(String uid) {
    if (uid.isEmpty) {
      return const Center(child: Text('Silakan login ulang'));
    }
    return StreamBuilder<List<MedicineModel>>(
      stream: _service.getAllMedicinesByPharmacy(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final medicines = snap.data ?? [];

        return Stack(
          children: [
            medicines.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.medication_outlined,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada obat di katalog',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap + untuk menambahkan obat',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: medicines.length,
                    itemBuilder: (_, i) => _medicineListTile(medicines[i], uid),
                  ),
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton.extended(
                backgroundColor: _kPurple,
                foregroundColor: Colors.white,
                onPressed: () => _showAddMedicineDialog(uid),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Obat'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _medicineListTile(MedicineModel med, String uid) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _kPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.medication_rounded,
            color: _kPurple,
            size: 22,
          ),
        ),
        title: Text(
          med.name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              med.category,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              currency.format(med.price),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kPurple,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: med.isAvailable,
              activeThumbColor: _kPurple,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (v) =>
                  _service.updateMedicine(med.id, {'isAvailable': v}),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.cancelled,
                size: 20,
              ),
              onPressed: () => _confirmDelete(med),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(MedicineModel med) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Obat?'),
        content: Text('Hapus "${med.name}" dari katalog?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              _service.deleteMedicine(med.id);
              Navigator.pop(context);
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.cancelled),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMedicineDialog(String uid) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'Umum');
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text(
            'Tambah Obat',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Obat',
                    prefixIcon: Icon(Icons.medication_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi / Indikasi',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga (Rp)',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    hintText: 'cth: Antibiotik, Vitamin, Umum',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty ||
                          priceCtrl.text.trim().isEmpty) {
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      final med = MedicineModel(
                        id: '',
                        pharmacyId: uid,
                        name: nameCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        price: double.tryParse(priceCtrl.text.trim()) ?? 0,
                        category: categoryCtrl.text.trim().isEmpty
                            ? 'Umum'
                            : categoryCtrl.text.trim(),
                        isAvailable: true,
                      );
                      await _service.addMedicine(med);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  // ── TAB 3: Pharmacy Profile ──────────────────────────────────────────────

  Widget _buildProfileTab(String uid) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _service.getPharmacyProfile(uid),
      builder: (context, snap) {
        if (!_profileLoaded && snap.hasData && snap.data != null) {
          _profileLoaded = true;
          final data = snap.data!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _nameCtrl.text = data['name'] ?? '';
                _addressCtrl.text = data['address'] ?? '';
                _areaCtrl.text = data['area'] ?? '';
                _phoneCtrl.text = data['phone'] ?? '';
                _openHoursCtrl.text = data['openHours'] ?? '08:00 - 21:00';
                _isOpen = data['isOpen'] ?? true;
              });
            }
          });
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _kPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy_rounded,
                    color: _kPurple,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Informasi Apotek',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Apotek',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Alamat Lengkap',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _areaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Area / Kecamatan',
                  hintText: 'cth: Kebayoran Baru',
                  prefixIcon: Icon(Icons.map_outlined),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _openHoursCtrl,
                decoration: const InputDecoration(
                  labelText: 'Jam Operasional',
                  hintText: 'cth: 08:00 - 22:00',
                  prefixIcon: Icon(Icons.access_time_outlined),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: _isOpen ? AppColors.accepted : AppColors.cancelled,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Apotek sedang buka',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Switch(
                      value: _isOpen,
                      activeThumbColor: _kPurple,
                      onChanged: (v) => setState(() => _isOpen = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: _savingProfile ? null : () => _saveProfile(uid),
                icon: _savingProfile
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_savingProfile ? 'Menyimpan...' : 'Simpan Profil'),
              ),
            ],
          ),
        );
      },
    );
  }
}
