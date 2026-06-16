import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../services/admin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin tab: manage all registered users (block/unblock/delete)
class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AdminService();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section: Users ───────────────────────────────────────────────
          const Text('Pengguna Terdaftar',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Kelola akun pengguna — block atau hapus akun bermasalah',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: service.getUsersStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const _EmptyState(
                    icon: Icons.people_outline,
                    message: 'Belum ada pengguna terdaftar');
              }
              return Column(
                children: docs.map((doc) {
                  final d = doc.data();
                  final isBlocked = d['isBlocked'] == true;
                  return _UserAdminCard(
                    uid: doc.id,
                    data: d,
                    isBlocked: isBlocked,
                    service: service,
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          // ── Section: Caregiver Management (detailed) ─────────────────────
          const Text('Mitra Caregiver',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Kelola akun mitra — block, unblock, atau hapus mitra',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: service.getCaregiversStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const _EmptyState(
                    icon: Icons.medical_services_outlined,
                    message: 'Belum ada mitra terdaftar');
              }
              return Column(
                children: docs.map((doc) {
                  final d = doc.data();
                  final isBlocked = d['isBlocked'] == true;
                  return _CaregiverAdminCard(
                    uid: doc.id,
                    data: d,
                    isBlocked: isBlocked,
                    service: service,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
//  User Card
// ────────────────────────────────────────────────────────────────────────────
class _UserAdminCard extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> data;
  final bool isBlocked;
  final AdminService service;

  const _UserAdminCard({
    required this.uid,
    required this.data,
    required this.isBlocked,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? data['displayName'] ?? 'Pengguna';
    final email = data['email'] ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isBlocked ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: isBlocked ? Colors.red.shade200 : AppColors.border),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isBlocked ? Colors.red.shade100 : AppColors.primaryLight,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'U',
            style: TextStyle(
                color: isBlocked ? Colors.red : AppColors.primary,
                fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
              ),
              if (isBlocked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6)),
                  child: Text('BLOCKED',
                      style: TextStyle(
                          fontSize: 9,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w800)),
                ),
            ]),
            Text(email,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (val) {
            if (val == 'block') {
              service.blockUser(uid, !isBlocked);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text(isBlocked ? 'User di-unblock' : 'User diblokir')));
            } else if (val == 'delete') {
              _showDeleteDialog(context);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'block',
              child: Row(children: [
                Icon(
                    isBlocked
                        ? Icons.lock_open_rounded
                        : Icons.block_rounded,
                    size: 18,
                    color: isBlocked ? AppColors.accepted : Colors.orange),
                const SizedBox(width: 8),
                Text(isBlocked ? 'Unblock User' : 'Block User'),
              ]),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                Icon(Icons.delete_outline, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('Hapus Akun', style: TextStyle(color: Colors.red)),
              ]),
            ),
          ],
        ),
      ]),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final name = data['name'] ?? 'Pengguna';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Akun?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Akun "$name" akan dihapus permanen dari sistem.',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              service.deleteUser(uid);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Akun berhasil dihapus')));
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
//  Caregiver Card (detailed version with rating)
// ────────────────────────────────────────────────────────────────────────────
class _CaregiverAdminCard extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> data;
  final bool isBlocked;
  final AdminService service;

  const _CaregiverAdminCard({
    required this.uid,
    required this.data,
    required this.isBlocked,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? '-';
    final spec = data['specialization'] ?? '-';
    final price = ((data['pricePerHour'] ?? 0) / 1000).toStringAsFixed(0);
    final rating = (data['rating'] ?? 0.0).toStringAsFixed(1);
    final reviews = data['totalReviews'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isBlocked ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: isBlocked ? Colors.red.shade200 : AppColors.border),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: isBlocked ? Colors.red.shade100 : AppColors.primaryLight,
          child: Text(name.isNotEmpty ? name[0] : 'C',
              style: TextStyle(
                  color: isBlocked ? Colors.red : AppColors.primary,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
              ),
              if (isBlocked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6)),
                  child: Text('BLOCKED',
                      style: TextStyle(
                          fontSize: 9,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w800)),
                ),
            ]),
            Text(spec,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            Row(children: [
              const Icon(Icons.star_rounded,
                  color: Color(0xFFFFC107), size: 13),
              Text(' $rating ($reviews ulasan)',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              Text('Rp ${price}k/jam',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (val) {
            if (val == 'block') {
              service.blockCaregiver(uid, !isBlocked);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      isBlocked ? 'Mitra di-unblock' : 'Mitra diblokir')));
            } else if (val == 'delete') {
              _showDeleteDialog(context, name);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'block',
              child: Row(children: [
                Icon(
                    isBlocked
                        ? Icons.lock_open_rounded
                        : Icons.block_rounded,
                    size: 18,
                    color: isBlocked ? AppColors.accepted : Colors.orange),
                const SizedBox(width: 8),
                Text(isBlocked ? 'Unblock Mitra' : 'Block Mitra'),
              ]),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                Icon(Icons.delete_outline, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('Hapus Mitra', style: TextStyle(color: Colors.red)),
              ]),
            ),
          ],
        ),
      ]),
    );
  }

  void _showDeleteDialog(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Mitra?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Akun mitra "$name" akan dihapus permanen dari sistem.',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              service.deleteCaregiver(uid);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mitra berhasil dihapus')));
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(message,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ]),
      ),
    );
  }
}
