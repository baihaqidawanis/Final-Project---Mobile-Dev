import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../services/admin_service.dart';

/// Admin tab: view all reports and take action (resolve/dismiss + block user/caregiver)
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _service = AdminService();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tab,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: '🔴 Menunggu'),
              Tab(text: 'Semua Laporan'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _ReportList(
                  stream: _service.getPendingReportsStream(),
                  service: _service,
                  emptyMessage: '✅ Tidak ada laporan yang menunggu'),
              _ReportList(
                  stream: _service.getReportsStream(),
                  service: _service,
                  emptyMessage: 'Belum ada laporan masuk'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportList extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final AdminService service;
  final String emptyMessage;

  const _ReportList({
    required this.stream,
    required this.service,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_circle_outline,
                  size: 56, color: AppColors.accepted),
              const SizedBox(height: 12),
              Text(emptyMessage,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14)),
            ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final d = doc.data();
            return _ReportCard(
              reportId: doc.id,
              data: d,
              service: service,
            );
          },
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String reportId;
  final Map<String, dynamic> data;
  final AdminService service;

  const _ReportCard({
    required this.reportId,
    required this.data,
    required this.service,
  });

  Color _statusColor(String status) => switch (status) {
        'resolved' => AppColors.accepted,
        'dismissed' => AppColors.textSecondary,
        'reviewed' => AppColors.pending,
        _ => Colors.red,
      };

  String _statusLabel(String status) => switch (status) {
        'resolved' => 'Selesai',
        'dismissed' => 'Ditolak',
        'reviewed' => 'Ditinjau',
        _ => 'Menunggu',
      };

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'pending';
    final statusColor = _statusColor(status);
    final isPending = status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPending ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isPending ? Colors.red.shade200 : AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──────────────────────────────────────────────────────
        Row(children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _typeColor(data['targetType'] ?? '').withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _typeLabel(data['targetType'] ?? ''),
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _typeColor(data['targetType'] ?? '')),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(data['reason'] ?? '-',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary)),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_statusLabel(status),
                style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 10),

        // ── Reporter & Target ────────────────────────────────────────────
        _infoRow(Icons.person_outline, 'Pelapor',
            '${data['reporterName'] ?? '-'} (${data['reporterRole'] ?? '-'})'),
        const SizedBox(height: 4),
        _infoRow(Icons.flag_outlined, 'Dilaporkan',
            data['targetName'] ?? '-'),
        const SizedBox(height: 4),

        if ((data['description'] ?? '').isNotEmpty) ...[
          _infoRow(Icons.notes, 'Keterangan', data['description']),
          const SizedBox(height: 4),
        ],

        if ((data['adminNote'] ?? '').isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const Icon(Icons.admin_panel_settings,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Catatan Admin: ${data['adminNote']}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.primary)),
              ),
            ]),
          ),

        // ── Actions ─────────────────────────────────────────────────────
        if (isPending) ...[
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Tolak', style: TextStyle(fontSize: 12)),
                onPressed: () =>
                    _handleAction(context, 'dismissed'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accepted,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                icon: const Icon(Icons.check, size: 16),
                label:
                    const Text('Selesaikan', style: TextStyle(fontSize: 12)),
                onPressed: () =>
                    _handleAction(context, 'resolved'),
              ),
            ),
          ]),
        ],
      ]),
    );
  }

  void _handleAction(BuildContext context, String newStatus) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
            newStatus == 'resolved'
                ? 'Selesaikan Laporan'
                : 'Tolak Laporan',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
              newStatus == 'resolved'
                  ? 'Tandai laporan ini sebagai selesai. Anda bisa menambahkan catatan tindakan.'
                  : 'Tolak laporan ini jika tidak terbukti atau tidak valid.',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: noteCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Catatan Admin (opsional)',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: newStatus == 'resolved'
                    ? AppColors.accepted
                    : AppColors.textSecondary),
            onPressed: () {
              service.updateReportStatus(
                  reportId, newStatus, noteCtrl.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(newStatus == 'resolved'
                      ? 'Laporan diselesaikan'
                      : 'Laporan ditolak')));
            },
            child: Text(newStatus == 'resolved' ? 'Selesaikan' : 'Tolak'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 14, color: AppColors.textSecondary),
      const SizedBox(width: 6),
      Text('$label: ',
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary)),
      Expanded(
        child: Text(value,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
      ),
    ]);
  }

  Color _typeColor(String type) => switch (type) {
        'caregiver' => AppColors.primary,
        'user' => AppColors.accent,
        'booking' => AppColors.pending,
        _ => AppColors.textSecondary,
      };

  String _typeLabel(String type) => switch (type) {
        'caregiver' => 'Mitra',
        'user' => 'Pengguna',
        'booking' => 'Booking',
        _ => 'Lainnya',
      };
}
