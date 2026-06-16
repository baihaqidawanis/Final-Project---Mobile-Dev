import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/services/auth_provider.dart';
import '../services/admin_service.dart';
import 'admin_users_screen.dart';
import 'admin_reports_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _adminService = AdminService();
  final _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Super Admin',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.textPrimary)),
              Text('Healink Control Panel',
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ]),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: _adminService.getPendingReportsStream(),
            builder: (context, snap) {
              final count = snap.data?.docs.length ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: AppColors.textPrimary),
                    onPressed: () {
                      _tabController.animateTo(2);
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        child: Text('$count',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            onPressed: () => auth.logout(),
            tooltip: 'Sign Out',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Overview'),
            Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Mitra'),
            Tab(icon: Icon(Icons.flag_outlined, size: 18), text: 'Laporan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(db: _db, adminService: _adminService),
          const AdminUsersScreen(),
          const AdminReportsScreen(),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  OVERVIEW TAB
// ════════════════════════════════════════════════════════════════════════════
class _OverviewTab extends StatelessWidget {
  final FirebaseFirestore db;
  final AdminService adminService;

  const _OverviewTab({required this.db, required this.adminService});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stats Row 1 ──────────────────────────────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: db.collection('bookings').snapshots(),
            builder: (context, snap) {
              final total = snap.data?.docs.length ?? 0;
              final pending = snap.data?.docs
                      .where((d) =>
                          (d.data() as Map)['status'] == 'pending')
                      .length ??
                  0;
              return Row(children: [
                _statCard('Total Booking', total.toString(),
                    Icons.assignment_outlined, AppColors.primary),
                const SizedBox(width: 12),
                _statCard('Menunggu', pending.toString(),
                    Icons.hourglass_empty, AppColors.pending),
              ]);
            },
          ),
          const SizedBox(height: 12),

          // ── Stats Row 2 ──────────────────────────────────────────────────
          Row(children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: db.collection('caregivers').snapshots(),
                builder: (context, snap) {
                  final total = snap.data?.docs.length ?? 0;
                  final blocked = snap.data?.docs
                          .where((d) =>
                              (d.data() as Map)['isBlocked'] == true)
                          .length ??
                      0;
                  return _rawStatCard(
                    label: 'Mitra Caregiver',
                    value: total.toString(),
                    sub: blocked > 0 ? '$blocked diblokir' : 'Semua aktif',
                    icon: Icons.medical_services_outlined,
                    color: AppColors.accent,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: db
                    .collection('users')
                    .where('role', isEqualTo: 'user')
                    .snapshots(),
                builder: (context, snap) {
                  final total = snap.data?.docs.length ?? 0;
                  return _rawStatCard(
                    label: 'Total Pengguna',
                    value: total.toString(),
                    sub: 'Terdaftar',
                    icon: Icons.people_outline,
                    color: AppColors.completed,
                  );
                },
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // ── Pending Reports Banner ───────────────────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: adminService.getPendingReportsStream(),
            builder: (context, snap) {
              final count = snap.data?.docs.length ?? 0;
              if (count == 0) return const SizedBox();
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.red.shade600, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$count laporan baru menunggu tindakan',
                      style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                ]),
              );
            },
          ),

          // ── Recent Bookings ──────────────────────────────────────────────
          const Text('Booking Terbaru',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: db
                .collection('bookings')
                .orderBy('createdAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const _EmptyState(
                    icon: Icons.assignment_outlined,
                    message: 'Belum ada booking');
              }
              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final status = d['status'] ?? 'pending';
                  final cancelledByAdmin = d['cancelledByAdmin'] == true;
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
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['familyName'] ?? '-',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.textPrimary)),
                          Text('→ ${d['caregiverName'] ?? '-'}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                          if (cancelledByAdmin)
                            const Text('Dibatalkan oleh Admin',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.red)),
                        ],
                      )),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(status,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: statusColor,
                                    fontWeight: FontWeight.w600)),
                          ),
                          if (status == 'pending') ...[
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () => _showForceCancelDialog(
                                  context, doc.id, adminService),
                              child: const Text('Force Cancel',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ],
                      ),
                    ]),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          // ── Mitra Caregiver ──────────────────────────────────────────────
          const Text('Mitra Caregiver',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: adminService.getCaregiversStream(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const _EmptyState(
                    icon: Icons.medical_services_outlined,
                    message: 'Belum ada mitra terdaftar');
              }
              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final isBlocked = d['isBlocked'] == true;
                  return _caregiverAdminCard(
                      context, doc.id, d, isBlocked, adminService);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _caregiverAdminCard(
    BuildContext context,
    String uid,
    Map<String, dynamic> d,
    bool isBlocked,
    AdminService service,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isBlocked ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isBlocked ? Colors.red.shade200 : AppColors.border),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor:
              isBlocked ? Colors.red.shade100 : AppColors.primaryLight,
          child: Text((d['name'] ?? 'C')[0],
              style: TextStyle(
                  color: isBlocked ? Colors.red : AppColors.primary,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(d['name'] ?? '-',
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
          Text(d['specialization'] ?? '-',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ])),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (val) {
            if (val == 'block') {
              service.blockCaregiver(uid, !isBlocked);
            } else if (val == 'delete') {
              _showDeleteCaregiverDialog(context, uid, d['name'] ?? '-', service);
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
            PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                const SizedBox(width: 8),
                const Text('Hapus Mitra',
                    style: TextStyle(color: Colors.red)),
              ]),
            ),
          ],
        ),
      ]),
    );
  }

  void _showForceCancelDialog(
      BuildContext context, String bookingId, AdminService service) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Force Cancel Booking',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Batalkan booking ini atas nama admin?',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            decoration: const InputDecoration(
                labelText: 'Alasan (opsional)',
                border: OutlineInputBorder()),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              service.forceCancelBooking(bookingId, ctrl.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Booking dibatalkan oleh admin')));
            },
            child: const Text('Force Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCaregiverDialog(
      BuildContext context, String uid, String name, AdminService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Mitra?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            'Akun mitra "$name" akan dihapus secara permanen dari sistem.',
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

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ]),
      ),
    );
  }

  Widget _rawStatCard({
    required String label,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          Text(sub,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
        ]),
      ]),
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
