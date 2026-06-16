import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../features/auth/services/auth_provider.dart';
import '../models/caregiver_profile_model.dart';
import '../services/caregiver_firestore_service.dart';
import '../widgets/caregiver_card.dart';
import 'caregiver_detail_screen.dart';

enum _SortOption { none, priceLow, priceHigh, rating }

class CaregiverListScreen extends StatefulWidget {
  const CaregiverListScreen({super.key});

  @override
  State<CaregiverListScreen> createState() => _CaregiverListScreenState();
}

class _CaregiverListScreenState extends State<CaregiverListScreen> {
  final _service = CaregiverFirestoreService();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  _SortOption _sortOption = _SortOption.none;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CaregiverProfileModel> _applyFilters(List<CaregiverProfileModel> all) {
    // Search filter
    var filtered = _searchQuery.isEmpty
        ? all
        : all.where((c) =>
            c.name.toLowerCase().contains(_searchQuery) ||
            c.specialization.toLowerCase().contains(_searchQuery) ||
            c.area.toLowerCase().contains(_searchQuery)).toList();

    // Sort
    switch (_sortOption) {
      case _SortOption.priceLow:
        filtered.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
        break;
      case _SortOption.priceHigh:
        filtered.sort((a, b) => b.pricePerHour.compareTo(a.pricePerHour));
        break;
      case _SortOption.rating:
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _SortOption.none:
        break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Caregiver',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari nama, spesialisasi, atau daerah...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),

          // Sort chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _sortChip('Semua', _SortOption.none, Icons.tune_rounded),
                const SizedBox(width: 8),
                _sortChip('Harga ↑', _SortOption.priceLow, Icons.arrow_upward_rounded),
                const SizedBox(width: 8),
                _sortChip('Harga ↓', _SortOption.priceHigh, Icons.arrow_downward_rounded),
                const SizedBox(width: 8),
                _sortChip('Rating', _SortOption.rating, Icons.star_rounded),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: StreamBuilder<List<CaregiverProfileModel>>(
              stream: _service.getCaregivers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmer();
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        const Text('Gagal memuat data',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                final all = snapshot.data ?? [];
                final filtered = _applyFilters(all);

                if (filtered.isEmpty) {
                  return _buildEmpty(all.isEmpty);
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 32, top: 4),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => CaregiverCard(
                    caregiver: filtered[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CaregiverDetailScreen(
                          caregiver: filtered[i],
                          familyId: auth.currentUser?.uid ?? '',
                          familyName: auth.userName.isNotEmpty
                              ? auth.userName
                              : (auth.currentUser?.email ?? 'Pengguna'),
                          isGuest: !isLoggedIn,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortChip(String label, _SortOption option, IconData icon) {
    final isSelected = _sortOption == option;
    return GestureDetector(
      onTap: () => setState(() => _sortOption = option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool noDataAtAll) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                noDataAtAll ? Icons.people_outline_rounded : Icons.search_off_rounded,
                size: 52,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              noDataAtAll ? 'Belum ada caregiver' : 'Tidak ditemukan',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              noDataAtAll
                  ? 'Caregiver yang mendaftar akan muncul di sini secara otomatis'
                  : 'Coba kata kunci atau filter yang berbeda',
              textAlign: TextAlign.center,
              style: const TextStyle(
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

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[50]!,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
