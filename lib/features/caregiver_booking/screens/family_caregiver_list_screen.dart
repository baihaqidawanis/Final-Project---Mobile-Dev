import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../models/caregiver_profile_model.dart';
import '../services/caregiver_firestore_service.dart';
import '../widgets/caregiver_card.dart';
import 'caregiver_detail_screen.dart';

// ── TEMPORARY: Replace with FirebaseAuth.instance.currentUser!.uid ──────────
const String kDummyFamilyId = 'family_test_001';
const String kDummyFamilyName = 'Test Family';
// ────────────────────────────────────────────────────────────────────────────

class FamilyCaregiverListScreen extends StatefulWidget {
  const FamilyCaregiverListScreen({super.key});

  @override
  State<FamilyCaregiverListScreen> createState() =>
      _FamilyCaregiverListScreenState();
}

class _FamilyCaregiverListScreenState
    extends State<FamilyCaregiverListScreen> {
  final _service = CaregiverFirestoreService();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Seed dummy data the first time the screen loads
    _service.seedDummyCaregivers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Find a Caregiver'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name or specialization...',
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
                    child: Text('Error: ${snapshot.error}',
                        style:
                            const TextStyle(color: AppColors.textSecondary)),
                  );
                }

                final all = snapshot.data ?? [];
                final filtered = _searchQuery.isEmpty
                    ? all
                    : all
                        .where((c) =>
                            c.name.toLowerCase().contains(_searchQuery) ||
                            c.specialization
                                .toLowerCase()
                                .contains(_searchQuery))
                        .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            size: 56, color: AppColors.textSecondary),
                        SizedBox(height: 12),
                        Text('No caregivers found',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24, top: 4),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => CaregiverCard(
                    caregiver: filtered[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CaregiverDetailScreen(
                          caregiver: filtered[i],
                          familyId: kDummyFamilyId,
                          familyName: kDummyFamilyName,
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

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 4,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[50]!,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
