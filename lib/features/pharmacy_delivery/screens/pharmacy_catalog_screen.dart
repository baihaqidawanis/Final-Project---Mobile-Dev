import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/services/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../models/pharmacy_profile_model.dart';
import '../models/medicine_model.dart';
import '../models/pharmacy_order_model.dart';
import '../services/pharmacy_firestore_service.dart';
import 'pharmacy_my_orders_screen.dart';

const _kPurple = Color(0xFF7B5EA7);

class PharmacyCatalogScreen extends StatefulWidget {
  final PharmacyProfileModel pharmacy;
  const PharmacyCatalogScreen({super.key, required this.pharmacy});

  @override
  State<PharmacyCatalogScreen> createState() =>
      _PharmacyCatalogScreenState();
}

class _PharmacyCatalogScreenState extends State<PharmacyCatalogScreen> {
  final _service = PharmacyFirestoreService();
  final _currency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // medicineId → quantity
  final Map<String, int> _cart = {};
  // medicineId → model (populated when item is added to cart)
  final Map<String, MedicineModel> _medicineMap = {};
  String _selectedCategory = 'Semua';

  int get _totalItems => _cart.values.fold(0, (s, q) => s + q);
  double get _totalPrice {
    double total = 0;
    _cart.forEach((id, qty) {
      final med = _medicineMap[id];
      if (med != null) total += med.price * qty;
    });
    return total;
  }

  void _increment(MedicineModel med) {
    setState(() {
      _medicineMap[med.id] = med;
      _cart[med.id] = (_cart[med.id] ?? 0) + 1;
    });
  }

  void _decrement(String id) {
    setState(() {
      final current = _cart[id] ?? 0;
      if (current <= 1) {
        _cart.remove(id);
      } else {
        _cart[id] = current - 1;
      }
    });
  }

  void _showCheckout() {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CheckoutSheet(
        cart: Map.from(_cart),
        medicineMap: Map.from(_medicineMap),
        totalPrice: _totalPrice,
        pharmacy: widget.pharmacy,
        service: _service,
        onOrderPlaced: () {
          setState(() => _cart.clear());
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const PharmacyMyOrdersScreen()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<MedicineModel>>(
        stream: _service.getMedicinesByPharmacy(widget.pharmacy.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final medicines = snap.data ?? [];
          final categories = [
            'Semua',
            ...{for (var m in medicines) m.category}
          ];
          final filtered = _selectedCategory == 'Semua'
              ? medicines
              : medicines
                  .where((m) => m.category == _selectedCategory)
                  .toList();

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: _kPurple,
                    foregroundColor: Colors.white,
                    expandedHeight: 130,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(widget.pharmacy.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      background: Container(
                        color: _kPurple,
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 48),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 13, color: Colors.white70),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.pharmacy.address.isNotEmpty
                                        ? widget.pharmacy.address
                                        : widget.pharmacy.area,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Category chips
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: categories.map((cat) {
                            final selected = _selectedCategory == cat;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedCategory = cat),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? _kPurple
                                      : AppColors.background,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  border: Border.all(
                                      color: selected
                                          ? _kPurple
                                          : AppColors.border),
                                ),
                                child: Text(cat,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                        color: selected
                                            ? Colors.white
                                            : AppColors.textSecondary)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  if (filtered.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.medication_outlined,
                                size: 64, color: AppColors.border),
                            SizedBox(height: 12),
                            Text('Belum ada obat tersedia',
                                style: TextStyle(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                          16, 12, 16, _totalItems > 0 ? 100 : 24),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final med = filtered[i];
                            return _MedicineCard(
                              medicine: med,
                              quantity: _cart[med.id] ?? 0,
                              currency: _currency,
                              onIncrement: () => _increment(med),
                              onDecrement: () => _decrement(med.id),
                            );
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    ),
                ],
              ),

              // Floating cart bar
              if (_totalItems > 0)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: GestureDetector(
                    onTap: _showCheckout,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: _kPurple,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _kPurple.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$_totalItems',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ),
                          const SizedBox(width: 12),
                          const Text('Lihat Keranjang',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                          const Spacer(),
                          Text(_currency.format(_totalPrice),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Medicine card ────────────────────────────────────────────────────────────

class _MedicineCard extends StatelessWidget {
  final MedicineModel medicine;
  final int quantity;
  final NumberFormat currency;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _MedicineCard({
    required this.medicine,
    required this.quantity,
    required this.currency,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: quantity > 0 ? _kPurple : AppColors.border,
          width: quantity > 0 ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _kPurple.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _kPurple.withValues(alpha: 0.08),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Center(
                child: Icon(Icons.medication_rounded,
                    color: _kPurple.withValues(alpha: 0.55), size: 40),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medicine.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(medicine.description,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text(currency.format(medicine.price),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _kPurple)),
                    ),
                    if (quantity == 0)
                      GestureDetector(
                        onTap: onIncrement,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                              color: _kPurple,
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 18),
                        ),
                      )
                    else
                      Row(
                        children: [
                          GestureDetector(
                            onTap: onDecrement,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                  border: Border.all(color: _kPurple),
                                  borderRadius:
                                      BorderRadius.circular(7)),
                              child: const Icon(Icons.remove,
                                  color: _kPurple, size: 16),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6),
                            child: Text('$quantity',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: _kPurple)),
                          ),
                          GestureDetector(
                            onTap: onIncrement,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                  color: _kPurple,
                                  borderRadius:
                                      BorderRadius.circular(7)),
                              child: const Icon(Icons.add,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Checkout bottom sheet ────────────────────────────────────────────────────

class _CheckoutSheet extends StatefulWidget {
  final Map<String, int> cart;
  final Map<String, MedicineModel> medicineMap;
  final double totalPrice;
  final PharmacyProfileModel pharmacy;
  final PharmacyFirestoreService service;
  final VoidCallback onOrderPlaced;

  const _CheckoutSheet({
    required this.cart,
    required this.medicineMap,
    required this.totalPrice,
    required this.pharmacy,
    required this.service,
    required this.onOrderPlaced,
  });

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isLoading = false;
  final _currency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void dispose() {
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan alamat pengiriman')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser!;

    final items = widget.cart.entries.map((e) {
      final med = widget.medicineMap[e.key]!;
      return OrderItem(
        medicineId: med.id,
        medicineName: med.name,
        price: med.price,
        quantity: e.value,
      );
    }).toList();

    final order = PharmacyOrderModel(
      orderId: '',
      userId: user.uid,
      userName: user.email ?? '',
      pharmacyId: widget.pharmacy.uid,
      pharmacyName: widget.pharmacy.name,
      items: items,
      totalPrice: widget.totalPrice,
      deliveryAddress: _addressCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      status: PharmacyOrderStatus.pending,
      createdAt: DateTime.now(),
    );

    await widget.service.createOrder(order);

    if (mounted) {
      Navigator.pop(context);
      widget.onOrderPlaced();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.cart.entries.toList();
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Ringkasan Pesanan',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Items list
                    ...items.map((e) {
                      final med = widget.medicineMap[e.key]!;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(children: [
                          Text('${e.value}x ',
                              style: const TextStyle(
                                  color: _kPurple,
                                  fontWeight: FontWeight.w700)),
                          Expanded(
                              child: Text(med.name,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary))),
                          Text(_currency.format(med.price * e.value),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                        ]),
                      );
                    }),
                    const Divider(height: 20),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppColors.textPrimary)),
                          Text(_currency.format(widget.totalPrice),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: _kPurple)),
                        ]),
                    const SizedBox(height: 20),

                    // Address
                    const Text('Alamat Pengiriman',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Masukkan alamat lengkap...',
                        prefixIcon:
                            const Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Notes
                    const Text('Catatan (opsional)',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesCtrl,
                      decoration: InputDecoration(
                        hintText:
                            'cth: Butuh resep dokter, perlu kadaluarsa jauh...',
                        prefixIcon: const Icon(Icons.note_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPurple,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isLoading ? null : _placeOrder,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Pesan Sekarang',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
