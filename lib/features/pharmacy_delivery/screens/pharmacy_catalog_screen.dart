import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
  State<PharmacyCatalogScreen> createState() => _PharmacyCatalogScreenState();
}

class _PharmacyCatalogScreenState extends State<PharmacyCatalogScreen> {
  final _service = PharmacyFirestoreService();
  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

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
        _medicineMap.remove(id);
      } else {
        _cart[id] = current - 1;
      }
    });
  }

  void _syncCart(Map<String, int> nextCart) {
    setState(() {
      _cart
        ..clear()
        ..addAll(nextCart);
      _medicineMap.removeWhere((id, _) => !_cart.containsKey(id));
    });
  }

  void _showCheckout() {
    if (_totalItems == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Keranjang masih kosong')));
      return;
    }
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CheckoutSheet(
        cart: Map.from(_cart),
        medicineMap: Map.from(_medicineMap),
        pharmacy: widget.pharmacy,
        service: _service,
        onCartChanged: _syncCart,
        onOrderPlaced: () {
          setState(() {
            _cart.clear();
            _medicineMap.clear();
          });
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PharmacyMyOrdersScreen()),
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
            ...{for (var m in medicines) m.category},
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
                    actions: [
                      _CartBadgeButton(
                        itemCount: _totalItems,
                        onPressed: _showCheckout,
                      ),
                      const SizedBox(width: 6),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        widget.pharmacy.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      background: Container(
                        color: _kPurple,
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 13,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.pharmacy.address.isNotEmpty
                                        ? widget.pharmacy.address
                                        : widget.pharmacy.area,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: categories.map((cat) {
                            final selected = _selectedCategory == cat;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedCategory = cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? _kPurple
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected
                                        ? _kPurple
                                        : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
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
                            Icon(
                              Icons.medication_outlined,
                              size: 64,
                              color: AppColors.border,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Belum ada obat tersedia',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        _totalItems > 0 ? 100 : 24,
                      ),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.78,
                            ),
                        delegate: SliverChildBuilderDelegate((context, i) {
                          final med = filtered[i];
                          return _MedicineCard(
                            medicine: med,
                            quantity: _cart[med.id] ?? 0,
                            currency: _currency,
                            onIncrement: () => _increment(med),
                            onDecrement: () => _decrement(med.id),
                          );
                        }, childCount: filtered.length),
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
                        horizontal: 20,
                        vertical: 14,
                      ),
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
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_totalItems',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Lihat Keranjang',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _currency.format(_totalPrice),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
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

class _CartBadgeButton extends StatelessWidget {
  final int itemCount;
  final VoidCallback onPressed;

  const _CartBadgeButton({required this.itemCount, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Keranjang',
      onPressed: onPressed,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.shopping_cart_outlined),
          if (itemCount > 0)
            Positioned(
              right: -7,
              top: -7,
              child: Container(
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  itemCount > 99 ? '99+' : '$itemCount',
                  style: const TextStyle(
                    color: _kPurple,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.medication_rounded,
                  color: _kPurple.withValues(alpha: 0.55),
                  size: 40,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  medicine.description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        currency.format(medicine.price),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kPurple,
                        ),
                      ),
                    ),
                    if (quantity == 0)
                      GestureDetector(
                        onTap: onIncrement,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _kPurple,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 18,
                          ),
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
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Icon(
                                Icons.remove,
                                color: _kPurple,
                                size: 16,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '$quantity',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: _kPurple,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: onIncrement,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: _kPurple,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 16,
                              ),
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
  final PharmacyProfileModel pharmacy;
  final PharmacyFirestoreService service;
  final ValueChanged<Map<String, int>> onCartChanged;
  final VoidCallback onOrderPlaced;

  const _CheckoutSheet({
    required this.cart,
    required this.medicineMap,
    required this.pharmacy,
    required this.service,
    required this.onCartChanged,
    required this.onOrderPlaced,
  });

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _isLoading = false;
  late final Map<String, int> _cart;
  XFile? _prescriptionImage;
  Uint8List? _prescriptionBytes;
  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  int get _totalItems => _cart.values.fold(0, (sum, qty) => sum + qty);

  double get _totalPrice {
    double total = 0;
    _cart.forEach((id, qty) {
      final med = widget.medicineMap[id];
      if (med != null) total += med.price * qty;
    });
    return total;
  }

  List<MapEntry<String, int>> get _items => _cart.entries
      .where((entry) => widget.medicineMap.containsKey(entry.key))
      .toList();

  @override
  void initState() {
    super.initState();
    _cart = Map.from(widget.cart);
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _commitCart() {
    widget.onCartChanged(Map.from(_cart));
  }

  void _increment(String id) {
    setState(() => _cart[id] = (_cart[id] ?? 0) + 1);
    _commitCart();
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
    _commitCart();
  }

  void _removeItem(String id) {
    setState(() => _cart.remove(id));
    _commitCart();
  }

  void _clearCart() {
    setState(_cart.clear);
    _commitCart();
  }

  Future<void> _pickPrescription(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _prescriptionImage = picked;
      _prescriptionBytes = bytes;
    });
  }

  void _showPrescriptionSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Ambil Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPrescription(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPrescription(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removePrescription() {
    setState(() {
      _prescriptionImage = null;
      _prescriptionBytes = null;
    });
  }

  Future<void> _placeOrder() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan obat ke keranjang dulu')),
      );
      return;
    }
    if (_addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan alamat pengiriman')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser!;

    try {
      PrescriptionUploadResult? prescriptionUpload;
      final prescriptionBytes = _prescriptionBytes;
      final prescriptionImage = _prescriptionImage;
      if (prescriptionBytes != null && prescriptionImage != null) {
        prescriptionUpload = await widget.service.uploadPrescriptionImage(
          userId: user.uid,
          pharmacyId: widget.pharmacy.uid,
          fileName: prescriptionImage.name,
          bytes: prescriptionBytes,
          contentType: prescriptionImage.mimeType ?? 'image/jpeg',
        );
      }

      final items = _items.map((e) {
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
        totalPrice: _totalPrice,
        deliveryAddress: _addressCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        prescriptionImageUrl: prescriptionUpload?.url,
        prescriptionImagePath: prescriptionUpload?.path,
        status: PharmacyOrderStatus.pending,
        createdAt: DateTime.now(),
      );

      await widget.service.createOrder(order);
      if (mounted) {
        Navigator.pop(context);
        widget.onOrderPlaced();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membuat pesanan. Coba lagi sebentar.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Keranjang Farmasi',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (items.isNotEmpty)
                    TextButton.icon(
                      onPressed: _isLoading ? null : _clearCart,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Kosongkan'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.cancelled,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (items.isEmpty) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 56,
                              color: _kPurple.withValues(alpha: 0.25),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Keranjang masih kosong',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Tambahkan obat dari katalog apotek ini',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kPurple,
                            side: const BorderSide(color: _kPurple),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Tambah Obat'),
                        ),
                      ),
                    ] else ...[
                      ...items.map((e) {
                        final med = widget.medicineMap[e.key]!;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: _kPurple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.medication_rounded,
                                  color: _kPurple,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      med.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _currency.format(med.price),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _QuantityButton(
                                    icon: Icons.remove,
                                    onTap: _isLoading
                                        ? null
                                        : () => _decrement(e.key),
                                    outlined: true,
                                  ),
                                  SizedBox(
                                    width: 32,
                                    child: Text(
                                      '${e.value}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: _kPurple,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  _QuantityButton(
                                    icon: Icons.add,
                                    onTap: _isLoading
                                        ? null
                                        : () => _increment(e.key),
                                  ),
                                ],
                              ),
                              IconButton(
                                tooltip: 'Hapus',
                                onPressed: _isLoading
                                    ? null
                                    : () => _removeItem(e.key),
                                icon: const Icon(Icons.close_rounded, size: 18),
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtotal ($_totalItems item)',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _currency.format(_totalPrice),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: _kPurple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Address
                      const Text(
                        'Alamat Pengiriman',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _addressCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Masukkan alamat lengkap...',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Notes
                      const Text(
                        'Catatan (opsional)',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notesCtrl,
                        decoration: InputDecoration(
                          hintText:
                              'cth: Butuh resep dokter, perlu kadaluarsa jauh...',
                          prefixIcon: const Icon(Icons.note_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text(
                        'Resep Dokter (opsional)',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: _prescriptionBytes == null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.description_outlined,
                                        size: 20,
                                        color: _kPurple,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Lampirkan foto resep jika obat membutuhkan resep dokter',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _isLoading
                                          ? null
                                          : _showPrescriptionSourceSheet,
                                      icon: const Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Upload Resep'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _kPurple,
                                        side: const BorderSide(color: _kPurple),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      _prescriptionBytes!,
                                      width: double.infinity,
                                      height: 140,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _isLoading
                                              ? null
                                              : _showPrescriptionSourceSheet,
                                          icon: const Icon(
                                            Icons.change_circle_outlined,
                                            size: 18,
                                          ),
                                          label: const Text('Ganti'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: _kPurple,
                                            side: const BorderSide(
                                              color: _kPurple,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        tooltip: 'Hapus resep',
                                        onPressed: _isLoading
                                            ? null
                                            : _removePrescription,
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: AppColors.cancelled,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _isLoading ? null : _placeOrder,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Pesan Sekarang',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
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

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool outlined;

  const _QuantityButton({
    required this.icon,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: outlined ? Colors.white : _kPurple,
            borderRadius: BorderRadius.circular(8),
            border: outlined ? Border.all(color: _kPurple) : null,
          ),
          child: Icon(
            icon,
            color: outlined ? _kPurple : Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
}
