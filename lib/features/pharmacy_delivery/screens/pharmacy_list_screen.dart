import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/services/auth_provider.dart';
import '../models/pharmacy_profile_model.dart';
import '../services/pharmacy_firestore_service.dart';
import 'pharmacy_catalog_screen.dart';
import 'pharmacy_my_orders_screen.dart';

const _kPurple = Color(0xFF7B5EA7);

class PharmacyListScreen extends StatefulWidget {
  const PharmacyListScreen({super.key});

  @override
  State<PharmacyListScreen> createState() => _PharmacyListScreenState();
}

class _PharmacyListScreenState extends State<PharmacyListScreen> {
  final _service = PharmacyFirestoreService();
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _kPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Pilih Apotek',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (auth.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.receipt_long_outlined),
              tooltip: 'Pesanan Saya',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PharmacyMyOrdersScreen()),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: _kPurple,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari apotek atau area...',
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha:0.65)),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withValues(alpha:0.18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),

          // Pharmacy list
          Expanded(
            child: StreamBuilder<List<PharmacyProfileModel>>(
              stream: _service.getPharmacies(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final all = snap.data ?? [];
                final filtered = _search.isEmpty
                    ? all
                    : all
                        .where((p) =>
                            p.name.toLowerCase().contains(_search) ||
                            p.area.toLowerCase().contains(_search))
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_pharmacy_outlined,
                            size: 72,
                            color: _kPurple.withValues(alpha:0.25)),
                        const SizedBox(height: 16),
                        Text(
                          _search.isEmpty
                              ? 'Belum ada apotek tersedia'
                              : 'Apotek tidak ditemukan',
                          style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary),
                        ),
                        if (_search.isEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Apotek akan muncul setelah\nmitra apotek mendaftar',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final pharmacy = filtered[i];
                    return _PharmacyCard(
                      pharmacy: pharmacy,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PharmacyCatalogScreen(pharmacy: pharmacy),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  final PharmacyProfileModel pharmacy;
  final VoidCallback onTap;

  const _PharmacyCard({required this.pharmacy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: _kPurple.withValues(alpha:0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _kPurple.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_pharmacy_rounded,
                    color: _kPurple, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pharmacy.name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text(
                      pharmacy.area.isNotEmpty
                          ? pharmacy.area
                          : pharmacy.address,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 13, color: Color(0xFFFFC107)),
                        const SizedBox(width: 3),
                        Text(
                          pharmacy.rating > 0
                              ? pharmacy.rating.toStringAsFixed(1)
                              : 'Baru',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                        ),
                        if (pharmacy.openHours.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.access_time,
                              size: 12,
                              color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(pharmacy.openHours,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pharmacy.isOpen
                      ? AppColors.accepted.withValues(alpha:0.1)
                      : AppColors.cancelled.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  pharmacy.isOpen ? 'Buka' : 'Tutup',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: pharmacy.isOpen
                        ? AppColors.accepted
                        : AppColors.cancelled,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
