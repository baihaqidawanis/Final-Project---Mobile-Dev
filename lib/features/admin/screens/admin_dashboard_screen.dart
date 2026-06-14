import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/services/auth_provider.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final client = Supabase.instance.client;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.favorite, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          const Text('Admin Panel', style: TextStyle(
            fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            onPressed: () => auth.logout(),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats cards
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: client.from('bookings').stream(primaryKey: ['id']),
              builder: (context, snap) {
                final list = snap.data ?? [];
                final total = list.length;
                final pending = list.where((d) => d['status'] == 'pending').length;
                return Row(children: [
                  _statCard('Total Booking', total.toString(), Icons.assignment_outlined, AppColors.primary),
                  const SizedBox(width: 12),
                  _statCard('Menunggu', pending.toString(), Icons.hourglass_empty, AppColors.pending),
                ]);
              },
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: client.from('caregivers').stream(primaryKey: ['id']),
              builder: (context, snap) {
                final total = snap.data?.length ?? 0;
                return Row(children: [
                  _statCard('Caregiver Aktif', total.toString(), Icons.medical_services_outlined, AppColors.accent),
                  const SizedBox(width: 12),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: client.from('profiles').stream(primaryKey: ['id']).eq('role', 'user'),
                    builder: (context, snap) {
                      final total = snap.data?.length ?? 0;
                      return _statCard('Total Pengguna', total.toString(), Icons.people_outline, AppColors.completed);
                    },
                  ),
                ]);
              },
            ),
            const SizedBox(height: 24),

            // Recent bookings
            const Text('Booking Terbaru', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: client.from('bookings').stream(primaryKey: ['id']),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Belum ada booking', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  );
                }

                // Sort by created_at descending and limit to 10
                final sortedList = List<Map<String, dynamic>>.from(list);
                sortedList.sort((a, b) {
                  final aTime = DateTime.parse(a['created_at'] as String);
                  final bTime = DateTime.parse(b['created_at'] as String);
                  return bTime.compareTo(aTime);
                });
                final recentList = sortedList.take(10).toList();

                return Column(
                  children: recentList.map((d) {
                    final status = d['status'] ?? 'pending';
                    final statusColor = switch (status) {
                      'accepted' => AppColors.accepted,
                      'completed' => AppColors.completed,
                      'cancelled' => AppColors.cancelled,
                      _ => AppColors.pending,
                    };
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(children: [
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d['family_name'] ?? d['familyName'] ?? '-', style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                            Text('→ ${d['caregiver_name'] ?? d['caregiverName'] ?? '-'}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        )),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(status, style: TextStyle(
                            fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),
            // Registered caregivers
            const Text('Mitra Caregiver', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: client.from('caregivers').stream(primaryKey: ['id']),
              builder: (context, snap) {
                final docs = snap.data ?? [];
                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Belum ada mitra terdaftar', style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return Column(children: docs.map((d) {
                  final price = (d['price_per_hour'] ?? d['pricePerHour'] ?? 0) as num;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryLight,
                        child: Text((d['name'] ?? 'C')[0],
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['name'] ?? '-', style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                          Text(d['specialization'] ?? '-',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      )),
                      Text('Rp ${(price / 1000).toStringAsFixed(0)}k/jam',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                    ]),
                  );
                }).toList());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
                Text(label, style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
