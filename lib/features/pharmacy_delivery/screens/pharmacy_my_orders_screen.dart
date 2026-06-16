import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _kPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pesanan Saya',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: PharmacyOrdersBody(uid: auth.currentUser?.uid ?? ''),
    );
  }
}

/// Body-only widget — reusable inside tab views without an AppBar.
class PharmacyOrdersBody extends StatelessWidget {
  final String uid;
  const PharmacyOrdersBody({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final service = PharmacyFirestoreService();
    return StreamBuilder<List<PharmacyOrderModel>>(
      stream: service.getOrdersByUser(uid),
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
                Icon(
                  Icons.receipt_long_outlined,
                  size: 72,
                  color: _kPurple.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Belum ada pesanan farmasi',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pesan obat dari apotek terdekat',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (_, i) =>
              _OrderCard(order: orders[i], service: service),
        );
      },
    );
  }
}

// ── Order card (stateful to handle confirmation dialog) ──────────────────────

class _OrderCard extends StatefulWidget {
  final PharmacyOrderModel order;
  final PharmacyFirestoreService service;

  const _OrderCard({required this.order, required this.service});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  static final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  static final _dateFormat = DateFormat('dd MMM yyyy, HH:mm');

  bool _confirming = false;

  void _showConfirmDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ConfirmDeliverySheet(
        order: widget.order,
        service: widget.service,
        onDone: () => setState(() => _confirming = false),
      ),
    );
  }

  // ── Status stepper ────────────────────────────────────────────────────────

  static const _steps = ['Dipesan', 'Dikemas', 'Dikirim', 'Diterima'];

  int _currentStep(PharmacyOrderStatus s) {
    switch (s) {
      case PharmacyOrderStatus.pending:
        return 0;
      case PharmacyOrderStatus.accepted:
        return 1;
      case PharmacyOrderStatus.shipped:
        return 2;
      case PharmacyOrderStatus.delivered:
        return 3;
      case PharmacyOrderStatus.cancelled:
        return -1; // cancelled state handled separately
    }
  }

  Widget _buildStepper(PharmacyOrderStatus status) {
    if (status == PharmacyOrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cancelled.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, size: 16, color: AppColors.cancelled),
            SizedBox(width: 8),
            Text(
              'Pesanan dibatalkan',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.cancelled,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final current = _currentStep(status);
    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stepIndex = i ~/ 2;
          final done = stepIndex < current;
          return Expanded(
            child: Container(
              height: 2,
              color: done ? _kPurple : AppColors.border,
            ),
          );
        }
        // Step dot
        final stepIndex = i ~/ 2;
        final done = stepIndex <= current;
        final isActive = stepIndex == current;
        return Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: done ? _kPurple : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: done ? _kPurple : AppColors.border,
                  width: 2,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: _kPurple.withValues(alpha: 0.3),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
              child: done
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              _steps[stepIndex],
              style: TextStyle(
                fontSize: 9,
                fontWeight: isActive || done
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: done ? _kPurple : AppColors.textSecondary,
              ),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
            // Pharmacy header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _kPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy_rounded,
                    color: _kPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.pharmacyName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _dateFormat.format(o.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _currency.format(o.totalPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _kPurple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Status stepper
            _buildStepper(o.status),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Items
            Text(
              o.items.map((e) => '${e.quantity}x ${e.medicineName}').join(', '),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            if (o.deliveryAddress.isNotEmpty) ...[
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

            // Confirm receipt button for shipped orders
            if (o.status == PharmacyOrderStatus.shipped) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _confirming ? null : _showConfirmDialog,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text(
                    'Konfirmasi Penerimaan',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],

            // Rating display for delivered orders
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
                                Icons.check_circle,
                                size: 14,
                                color: AppColors.accepted,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Pesanan diterima',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accepted,
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
                          SizedBox(width: 6),
                          Text(
                            'Pesanan telah diterima',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accepted,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Confirm delivery bottom sheet ────────────────────────────────────────────

class _ConfirmDeliverySheet extends StatefulWidget {
  final PharmacyOrderModel order;
  final PharmacyFirestoreService service;
  final VoidCallback onDone;

  const _ConfirmDeliverySheet({
    required this.order,
    required this.service,
    required this.onDone,
  });

  @override
  State<_ConfirmDeliverySheet> createState() => _ConfirmDeliverySheetState();
}

class _ConfirmDeliverySheetState extends State<_ConfirmDeliverySheet> {
  double? _rating;
  final _reviewCtrl = TextEditingController();
  bool _isLoading = false;
  bool _skipRating = false;

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _isLoading = true);
    try {
      await widget.service.confirmDelivery(
        widget.order.orderId,
        widget.order.pharmacyId,
        rating: _skipRating ? null : _rating,
        review: _skipRating ? null : _reviewCtrl.text.trim(),
        userName: widget.order.userName,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onDone();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Penerimaan dikonfirmasi. Terima kasih!'),
            backgroundColor: AppColors.accepted,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Success icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.accepted.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                color: AppColors.accepted,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Pesanan Sudah Diterima?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Konfirmasi jika obat sudah tiba di tanganmu',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Rating section
            if (!_skipRating) ...[
              const Text(
                'Beri Rating (opsional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemSize: 40,
                glow: false,
                itemBuilder: (ctx, idx) =>
                    const Icon(Icons.star, color: Color(0xFFFFC107)),
                onRatingUpdate: (r) => setState(() => _rating = r),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _reviewCtrl,
                decoration: InputDecoration(
                  hintText: 'Tulis ulasanmu (opsional)...',
                  prefixIcon: const Icon(Icons.rate_review_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() => _skipRating = true),
                child: const Text(
                  'Lewati, langsung konfirmasi',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rating tidak akan dikirimkan',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() => _skipRating = false),
                child: const Text(
                  'Beri rating tetap',
                  style: TextStyle(color: _kPurple),
                ),
              ),
            ],

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accepted,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isLoading ? null : _confirm,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Ya, Sudah Diterima',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
