import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/services/auth_provider.dart';
import '../models/pharmacy_order_model.dart';
import '../services/pharmacy_firestore_service.dart';

const _kPurple = Color(0xFF7B5EA7);

class PharmacyMyOrdersScreen extends StatelessWidget {
  const PharmacyMyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final service = PharmacyFirestoreService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _kPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Pesanan Saya',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<List<PharmacyOrderModel>>(
        stream: service.getOrdersByUser(auth.currentUser?.uid ?? ''),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snap.data ?? [];
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 72, color: _kPurple.withValues(alpha: 0.25)),
                  const SizedBox(height: 16),
                  const Text('Belum ada pesanan',
                      style: TextStyle(
                          fontSize: 15, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  const Text('Pesan obat dari apotek terdekat',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (_, i) => _OrderCard(order: orders[i]),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final PharmacyOrderModel order;
  const _OrderCard({required this.order});

  static final _currency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  static final _dateFormat = DateFormat('dd MMM yyyy, HH:mm');

  Color _statusColor(PharmacyOrderStatus s) {
    switch (s) {
      case PharmacyOrderStatus.pending:
        return AppColors.pending;
      case PharmacyOrderStatus.processing:
        return AppColors.accepted;
      case PharmacyOrderStatus.shipped:
        return const Color(0xFF2196F3);
      case PharmacyOrderStatus.delivered:
        return AppColors.accepted;
      case PharmacyOrderStatus.cancelled:
        return AppColors.cancelled;
    }
  }

  IconData _statusIcon(PharmacyOrderStatus s) {
    switch (s) {
      case PharmacyOrderStatus.pending:
        return Icons.hourglass_empty_rounded;
      case PharmacyOrderStatus.processing:
        return Icons.inventory_2_outlined;
      case PharmacyOrderStatus.shipped:
        return Icons.local_shipping_outlined;
      case PharmacyOrderStatus.delivered:
        return Icons.check_circle_outline;
      case PharmacyOrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  String _statusLabel(PharmacyOrderStatus s) {
    switch (s) {
      case PharmacyOrderStatus.pending:
        return 'Menunggu';
      case PharmacyOrderStatus.processing:
        return 'Diproses';
      case PharmacyOrderStatus.shipped:
        return 'Dikirim';
      case PharmacyOrderStatus.delivered:
        return 'Terkirim';
      case PharmacyOrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: _kPurple.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_pharmacy_rounded,
                    color: _kPurple, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(order.pharmacyName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon(order.status),
                        size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(_statusLabel(order.status),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Text(
              order.items
                  .map((e) => '${e.quantity}x ${e.medicineName}')
                  .join(', '),
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (order.deliveryAddress.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(order.deliveryAddress,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ],
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(children: [
              Text(_dateFormat.format(order.createdAt),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const Spacer(),
              Text(_currency.format(order.totalPrice),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _kPurple)),
            ]),
          ],
        ),
      ),
    );
  }
}
